class BankTransaction < ApplicationRecord
  include Versions
  include TransactionPaidInvoices
  belongs_to :bank_statement
  has_one :account_activity

  scope :unbinded, lambda {
    where('id NOT IN (SELECT bank_transaction_id FROM account_activities where bank_transaction_id IS NOT NULL)')
  }

  def binded?
    account_activity.present?
  end

  def binded_invoice
    return unless binded?

    account_activity.invoice
  end

  def registrar
    @registrar ||= Invoice.find_by(reference_no: parsed_ref_number)&.buyer
  end

  def autobindable?
    !binded? && registrar && invoice.payable? ? true : false
  rescue NoMethodError
    false
  end

  # For successful binding, reference number, invoice id and sum must match with the invoice
  def autobind_invoice(manual: false)
    return unless autobindable?

    channel = manual ? 'admin_payment' : 'system_payment'
    create_internal_payment_record(channel: channel, invoice: invoice, registrar: registrar)
  end

  def create_internal_payment_record(channel: nil, invoice:, registrar:)
    if channel.nil?
      create_activity(invoice.buyer, invoice)
      return
    end

    payment_order = PaymentOrder.new_with_type(type: channel, invoice: invoice)
    payment_order.save!

    if create_activity(registrar, invoice)
      payment_order.paid!
    else
      payment_order.update(notes: 'Failed to create activity', status: 'failed')
    end
  end

  def bind_invoice(invoice_no, manual: false)
    if binded?
      errors.add(:base, I18n.t('transaction_is_already_binded'))
      return
    end

    invoice = Invoice.find_by(number: invoice_no)
    errors.add(:base, I18n.t('invoice_was_not_found')) unless invoice
    validate_invoice_data(invoice)
    return if errors.any?

    create_internal_payment_record(channel: (manual ? 'admin_payment' : nil), invoice: invoice,
                                   registrar: invoice.buyer)
  end

  def validate_invoice_data(invoice)
    if invoice.paid?
      errors.add(:base, I18n.t('invoice_is_already_binded'))
      return
    end

    if invoice.cancelled?
      errors.add(:base, I18n.t('cannot_bind_cancelled_invoice'))
      return
    end

    errors.add(:base, I18n.t('invoice_and_transaction_sums_do_not_match')) if invoice.total != sum
  end

  def create_activity(registrar, invoice)
    activity = AccountActivity.new(account: registrar.cash_account, bank_transaction: self,
                                   invoice: invoice, sum: invoice.subtotal,
                                   currency: currency, description: description,
                                   activity_type: AccountActivity::ADD_CREDIT)

    if activity.save
      reset_pending_registrar_balance_reload
      true
    else
      false
    end
  end

  def parsed_ref_number
    reference_no || ref_number_from_description
  end

  private

  def reset_pending_registrar_balance_reload
    return unless registrar.settings['balance_auto_reload']

    registrar.settings['balance_auto_reload'].delete('pending')
    registrar.save!
  end

  def ref_number_from_description
    matches = description.to_s.scan(Billing::ReferenceNo::MULTI_REGEXP).flatten
    matches.detect { |m| break m if m.length == 7 || valid_ref_no?(m) }
  end

  def valid_ref_no?(match)
    return true if Billing::ReferenceNo.valid?(match) && Registrar.find_by(reference_no: match)
  end
end
