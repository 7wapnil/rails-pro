module Payments
  class WirecardController < PaymentsController
    def provider
      ::Payments::Wirecard::Provider.new
    end
  end
end
