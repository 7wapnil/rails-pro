module Payments
  class Deposit < Operation
    include Methods

    protected

    def execute_operation
      # TODO: Here must be logic related to internal deposit process

      @transaction.id = rand(99999)
      provider.payment_page_url(@transaction)
    end

    private

    def provider
      find_method_provider(@transaction.method).new
    end
  end
end
