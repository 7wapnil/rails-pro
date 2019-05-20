module Payments
  class Service
    def deposit(transaction)
      validate_transaction!(transaction)

      provider = transaction.deposit_provider.new
      provider.deposit!(transaction)
    rescue Errors::GatewayError
      # handle errors
    end

    private

    def validate_transaction!(transaction)
      raise Errors::InvalidTransaction unless transaction.valid?
    end
  end
end
