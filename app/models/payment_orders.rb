module PaymentOrders
  PAYMENT_INTERMEDIARIES = ENV['payments_intermediaries'].to_s.strip.split(', ').freeze
  PAYMENT_BANKLINK_BANKS = ENV['payments_banks'].to_s.strip.split(', ').freeze
  PAYMENT_METHODS = [PAYMENT_INTERMEDIARIES, PAYMENT_BANKLINK_BANKS].flatten.freeze

  def self.create_with_type(type, invoice, opts = {})
    raise ArgumentError unless PAYMENT_METHODS.include?(type)

    if PAYMENT_BANKLINK_BANKS.include?(type)
      BankLink.new(type, invoice, opts)
    elsif type == 'every_pay'
      EveryPay.new(type, invoice, opts)
    end
  end
end
