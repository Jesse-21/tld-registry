class Registrar
  class PaymentsController < BaseController
    protect_from_forgery except: [:back, :callback]

    skip_authorization_check # actually anyone can pay, no problems at all
    skip_before_action :authenticate_user!, :check_ip_restriction, only: [:back, :callback]
    before_action :check_supported_payment_method

    def pay
      invoice = Invoice.find(params[:invoice_id])
      opts = {
        return_url: self.registrar_return_payment_with_url(
          params[:bank], invoice_id: invoice.id
        ),
        response_url: self.registrar_response_payment_with_url(
          params[:bank], invoice_id: invoice.id
        )
      }
      @payment = ::Payments.create_with_type(params[:bank], invoice, opts)
      @payment.create_transaction
    end

    def back
      invoice = Invoice.find(params[:invoice_id])
      opts = { response: params }
      @payment = ::Payments.create_with_type(params[:bank], invoice, opts)
      if @payment.valid_response_from_intermediary? && @payment.settled_payment?
        @payment.complete_transaction

        if invoice.binded?
          flash[:notice] = t(:pending_applied)
        else
          flash[:alert] = t(:something_wrong)
        end
      else
        flash[:alert] = t(:something_wrong)
      end
      redirect_to registrar_invoice_path(invoice)
    end

    def callback
      invoice = Invoice.find(params[:invoice_id])
      opts = { response: params }
      @payment = ::Payments.create_with_type(params[:bank], invoice, opts)

      if @payment.valid_response_from_intermediary? && @payment.settled_payment?
        @payment.complete_transaction
      end

      render status: 200, json: { status: 'ok' }
    end

    private

    def check_supported_payment_method
      unless supported_payment_method?
        raise StandardError.new("Not supported payment method")
      end
    end


    def supported_payment_method?
      Payments::PAYMENT_METHODS.include?(params[:bank])
    end
  end
end
