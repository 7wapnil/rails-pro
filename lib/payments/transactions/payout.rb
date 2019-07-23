# frozen_string_literal: true

module Payments
  module Transactions
    class Payout < ::Payments::Transactions::Base
      attr_accessor :details, :withdrawal

      validates :withdrawal, presence: true
      validates :details, presence: true

      def amount
        return @amount unless @amount.is_a?(Numeric)

        -@amount.abs
      end
    end
  end
end
