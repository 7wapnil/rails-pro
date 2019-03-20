# frozen_string_literal: true

module Transactions
  class TransactionsResolver < ApplicationService
    ALL_FILTER_OPTION = 'all'
    FILTER_OPTIONS = [EntryRequest::WITHDRAW,
                      EntryRequest::DEPOSIT,
                      ALL_FILTER_OPTION].freeze

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
      invalid_filter! unless valid_filter?

      return EntryRequest.all_transactions if all_filter?

      EntryRequest.where(kind: args[:filter])
    end

    def invalid_filter!
      raise GraphQL::ExecutionError,
            I18n.t('errors.messages.graphql.transactions.kind.invalid',
                   kind: args[:filter])
    end

    def all_filter?
      args[:filter] == ALL_FILTER_OPTION
    end

    def valid_filter?
      FILTER_OPTIONS.include?(args[:filter])
    end
  end
end
