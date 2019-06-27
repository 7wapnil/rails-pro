# frozen_string_literal: true

module Payments
  module Transactions
    class Base
      include ::ActiveModel::Model

      attr_accessor :id, :method, :customer, :amount, :currency_code

      validates :method, :customer, :amount, :currency_code, presence: true
      validates :amount, numericality: true

      def currency
        @currency ||= Currency.find_by(code: currency_code)
      end

      def wallet
        @wallet ||= Wallets::FindOrCreate.call(
          customer: customer,
          currency: currency
        )
      end
    end
  end
end
