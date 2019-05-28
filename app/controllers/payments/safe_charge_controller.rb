module Payments
  class SafeChargeController < PaymentsController
    def provider
      ::Payments::SafeCharge::Provider.new
    end
  end
end
