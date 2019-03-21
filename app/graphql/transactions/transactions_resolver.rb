# frozen_string_literal: true

module Transactions
  class TransactionsResolver < ApplicationService
    FILTER_OPTIONS = [EntryRequest::WITHDRAW,
                      EntryRequest::DEPOSIT].freeze

    def initialize(filter:, current_customer:)
      @filter = filter
      @current_customer = current_customer
    end

    def call
      invalid_filter! unless valid_filter?

      EntryRequest.transactions
                  .where(customer_id: @current_customer)
                  .tap { |query| return apply_kind(query) }
    end

    private

    attr_reader :filter, :current_customer

    def invalid_filter!
      raise GraphQL::ExecutionError,
            I18n.t('errors.messages.graphql.transactions.kind.invalid',
                   kind: filter)
    end

    def valid_filter?
      FILTER_OPTIONS.include?(filter) || filter.nil?
    end

    def apply_kind(query)
      return query.where(kind: filter) if filter.present?

      query
    end
  end
end
