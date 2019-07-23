# frozen_string_literal: true

module Payments
  class Provider
    attr_reader :transaction

    def initialize(transaction)
      @transaction = transaction
    end
  end
end
