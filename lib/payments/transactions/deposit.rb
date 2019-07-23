# frozen_string_literal: true

module Payments
  module Transactions
    class Deposit < ::Payments::Transactions::Base
      attr_accessor :bonus_code
      attr_reader :amount

      def bonus
        @bonus ||= Bonus.from_code(bonus_code)
      end
    end
  end
end
