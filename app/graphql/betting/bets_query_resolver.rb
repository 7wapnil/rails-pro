# frozen_string_literal: true

module Betting
  class BetsQueryResolver
    DATE_FORMAT_REGEXP = %r[^[0-9]{2}/[0-9]{2}/[0-9]{4}$]

    def initialize(args:, customer:)
      @args = args
      @customer = customer
    end

    def resolve
      @query = base_query
      @query = filter_by_ids
      @query = filter_by_kind
      @query = filter_by_status
      @query = filter_by_date
      @query = filter_by_excluded_statuses

      query
    end

    private

    attr_reader :args, :customer, :query

    def base_query
      Bet.includes(:currency, bet_legs: %i[odd market event title])
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
      return query if args[:settlementStatus].blank?

      query.where(settlement_status: args[:settlementStatus])
    end

    def filter_by_date
      return query if args[:dateRange].blank?

      query.where(created_at: dates_selector)
    end

    def filter_by_excluded_statuses
      return query if args[:excludedStatuses].blank?

      query.where.not(status: args[:excludedStatuses])
    end

    def dates_selector
      return if args[:dateRange].blank?
      return specific_day if args[:dateRange].match(DATE_FORMAT_REGEXP)

      base_date_range
    end

    def specific_day
      Date.parse(args[:dateRange]).all_day
    end

    def base_date_range
      case args[:dateRange]
      when 'today'
        Time.zone.now.all_day
      when 'week'
        Time.zone.now.all_week
      else
        Time.zone.now.all_month
      end
    end
  end
end
