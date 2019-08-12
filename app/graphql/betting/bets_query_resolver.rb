# frozen_string_literal: true

module Betting
  class BetsQueryResolver
    def initialize(args:, customer:)
      @args = args
      @customer = customer
    end

    def resolve
      @query = base_query
      @query = filter_by_ids
      @query = filter_by_kind
      @query = filter_by_status

      query
    end

    private

    attr_reader :args, :customer, :query

    def base_query
      Bet.includes(:currency, odd: { market: { event: :title } })
         .where(customer: customer)
         .order(created_at: :desc)
    end

    def filter_by_ids
      return query if args[:ids].blank?

      query.where(id: args[:ids])
    end

    def filter_by_kind
      return query if args[:kind].blank?

      query.where(titles: { kind: args[:kind] })
    end

    def filter_by_status
      return query if args[:settlement_status].blank?

      query.where(settlement_status: args[:settlement_status])
    end
  end
end
