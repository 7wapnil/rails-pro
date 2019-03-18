# frozen_string_literal: true

module Transactions
  class TransactionsResolver < ApplicationService
    FILTER_OPTIONS = [EntryRequest::WITHDRAW, EntryRequest::DEPOSIT].freeze

    def initialize(args:, current_customer:)
      @args = args
      @current_customer = current_customer
    end

    def call
      filtered_entry_requests
        .where(customer_id: @current_customer)
        .order(created_at: :desc)
    end

    private

    attr_reader :args, :current_customer

    def filtered_entry_requests
      return EntryRequest.where(kind: args[:filter]) if valid_filter?

      raise GraphQL::ExecutionError,
            I18n.t('errors.messages.graphql.transactions.kind.invalid',
                   kind: args[:filter])
    end

    def valid_filter?
      FILTER_OPTIONS.include?(args[:filter])
    end
  end
end
