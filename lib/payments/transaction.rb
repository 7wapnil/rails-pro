# frozen_string_literal: true

module Payments
  class Transaction
    include ::ActiveModel::Model

    attr_accessor :id, :method, :customer, :amount, :currency, :bonus_code

    validates :method, :customer, :amount, :currency, presence: true
    validates :amount, numericality: true

    def wallet
      @wallet ||= Wallets::FindOrCreate.call(
        customer: customer,
        currency: currency
      )
    end

    def bonus
      @bonus ||= Bonus.find_by(code: bonus_code)
    end
  end
end
