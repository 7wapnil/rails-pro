# frozen_string_literal: true

module Payments
  module Transactions
    class Validation
      include ::ActiveModel::Model

      attr_accessor :method, :customer, :currency

      validates :method, :customer, :currency, presence: true
    end
  end
end
