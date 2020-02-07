module PaymentOrders
  class EveryPay < Base
    USER       = ENV['payments_every_pay_api_user'].freeze
    KEY        = ENV['payments_every_pay_api_key'].freeze
    ACCOUNT_ID = ENV['payments_every_pay_seller_account'].freeze
    SUCCESSFUL_PAYMENT = %w(settled authorized).freeze

    def form_fields
      base_json = base_params
      base_json[:nonce] = SecureRandom.hex(15)
      hmac_fields = (base_json.keys + ['hmac_fields']).sort.uniq!

      base_json[:hmac_fields] = hmac_fields.join(',')
      hmac_string = hmac_fields.map { |key, _v| "#{key}=#{base_json[key]}" }.join('&')
      hmac = OpenSSL::HMAC.hexdigest('sha1', KEY, hmac_string)
      base_json[:hmac] = hmac

      base_json
    end

    def valid_response_from_intermediary?
      return false unless response

      valid_hmac? && valid_amount? && valid_account?
    end

    def settled_payment?
      SUCCESSFUL_PAYMENT.include?(response[:payment_state])
    end

    def complete_transaction
      return unless valid_response_from_intermediary? && settled_payment?

      transaction = compose_or_find_transaction

      transaction.sum = response[:amount]
      transaction.paid_at = Date.strptime(response[:timestamp], '%s')
      transaction.buyer_name = response[:cc_holder_name]

      transaction.save!
      transaction.bind_invoice(invoice.number)
      if transaction.errors.empty?
        Rails.logger.info("Invoice ##{invoice.number} marked as paid")
      else
        Rails.logger.error("Failed to bind invoice ##{invoice.number}")
      end
    end

    private

    def base_params
      {
        api_username: USER,
        account_id: ACCOUNT_ID,
        timestamp: Time.now.to_i.to_s,
        callback_url: response_url,
        customer_url: return_url,
        amount: number_with_precision(invoice.total, precision: 2),
        order_reference: SecureRandom.hex(15),
        transaction_type: 'charge',
        hmac_fields: ''
      }.with_indifferent_access
    end

    def valid_hmac?
      hmac_fields = response[:hmac_fields].split(',')
      hmac_hash = {}
      hmac_fields.map do |field|
        symbol = field.to_sym
        hmac_hash[symbol] = response[symbol]
      end

      hmac_string = hmac_hash.map { |key, _v| "#{key}=#{hmac_hash[key]}" }.join('&')
      expected_hmac = OpenSSL::HMAC.hexdigest('sha1', KEY, hmac_string)
      expected_hmac == response[:hmac]
    end

    def valid_amount?
      invoice.total == BigDecimal(response[:amount])
    end

    def valid_account?
      response[:account_id] == ACCOUNT_ID
    end
  end
end
