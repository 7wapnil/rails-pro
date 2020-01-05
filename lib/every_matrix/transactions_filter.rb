# frozen_string_literal: true

module EveryMatrix
  class TransactionsFilter
    include DateIntervalFilters

    EXCLUDED_COLUMNS = {
      customers: %i[customer]
    }.freeze

    attr_reader :source

    def initialize(source:, query_params: {}, page: nil)
      @source = source
      @query_params = prepare_interval_filter(query_params, :created_at)
      @page = page
    end

    def search
      @source.joins(:entry)
             .includes(:customer, :currency, :play_item,
                       :vendor, :content_provider)
             .ransack(@query_params, search_key: :transactions)
    end

    def transactions
      TransactionDecorator.decorate_collection(
        search.result.order(id: :desc).page(@page)
      )
    end
  end
end
