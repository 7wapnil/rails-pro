# frozen_string_literal: true

module Payments
  module Transactions
    class Withdrawal < ::Payments::Transactions::Base
      attr_accessor :password, :details

      validates :password, :details, presence: true
    end
  end
end
