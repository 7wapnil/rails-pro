module Payments
  class SafeChargeController < PaymentsController
    def notification
      render plain: "SafeCharge notification data: #{params}"
    end

    def provider
      ::Payments::SafeCharge::Provider.new
    end
  end
end
