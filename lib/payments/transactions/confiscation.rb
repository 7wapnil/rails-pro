# frozen_string_literal: true

module Payments
  module Transactions
    class Confiscation < ::Payments::Transactions::Base
      attr_accessor :initiator

      validates :initiator, presence: true
    end
  end
end
