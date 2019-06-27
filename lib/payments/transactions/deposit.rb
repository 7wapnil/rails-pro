# frozen_string_literal: true

module Payments
  module Transactions
    class Deposit < ::Payments::Transactions::Base
      attr_accessor :bonus_code

      def bonus
        @bonus ||= Bonus.find_by(code: bonus_code)
      end
    end
  end
end
