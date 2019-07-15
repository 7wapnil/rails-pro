# frozen_string_literal: true

module Customers
  class AvailableWithdrawalMethods < ApplicationService
    def initialize(customer:)
      @customer = customer
    end

    def call
      method_for_choosing
        .or(methods_for_entering)
        .order(created_at: :desc)
        .select(:id, :mode, 'customer_transactions.details')
        .uniq(&:details)
    end

    private

    attr_reader :customer

    def deposits_with_details
      customer
        .entry_requests
        .deposit
        .succeeded
        .joins(:deposit, :entry)
        .where.not(customer_transactions: { details: nil })
    end

    def method_for_choosing
      deposits_with_details
        .where(mode: ::Payments::Methods::CHOSEN_PAYMENT_METHODS)
    end

    def methods_for_entering
      ids = deposits_with_details
            .where(mode: ::Payments::Methods::ENTERED_PAYMENT_METHODS)
            .select(:id, :mode)
            .uniq(&:mode)
            .map(&:id)

      customer.entry_requests.joins(:deposit, :entry).where(id: ids)
    end
  end
end
