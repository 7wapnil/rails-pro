# frozen_string_literal: true

module Wallets
  class BalanceVerification < ApplicationService
    delegate :customer, to: :wallet

    def initialize(wallet)
      @wallet = wallet
    end

    def call
      return negative_balance_reached if wallet.negative_balance?

      positive_balance_reached
    end

    private

    attr_reader :wallet

    def negative_balance_reached
      LabelJoin.find_or_create_by(negative_balance_attributes)
    end

    def positive_balance_reached
      LabelJoin
        .find_by(negative_balance_attributes)
        &.delete
    end

    def negative_balance_attributes
      @negative_balance_attributes ||= {
        labelable: customer,
        label: Label.negative_balance
      }
    end
  end
end
