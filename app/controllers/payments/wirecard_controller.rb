module Payments
  class WirecardController < PaymentsController
    def notification
      data = Base64.decode64(params['response-base64'])
      render plain: "WireCard notification data: #{data}"
    end

    def provider
      ::Payments::Wirecard::Provider.new
    end
  end
end
