module Payments
  class Operation < ApplicationService
    attr_reader :transaction

    def initialize(transaction)
      @transaction = transaction
    end

    def call
      validate_transaction!
      execute_operation
    end

    protected

    def execute_operation
      raise ::NotImplementedError
    end

    def validate_transaction!
      return if transaction.valid?

      raise Payments::InvalidTransactionError.new(transaction)
    end
  end
end
