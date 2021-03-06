# frozen_string_literal: true

module Events
  class MarketsQueryResolver < ApplicationService
    def initialize(args: {})
      @args = args.to_h.with_indifferent_access
    end

    def call
      raise 'Event ID is required' unless event_id

      markets
    end

    private

    attr_reader :args

    def event_id
      @event_id ||= args[:eventId]
    end

    def markets
      query = Market.for_displaying
                    .where(event_id: event_id)
      query = filter_by_category(args[:category], query)
      query = filter_by(:priority, args[:priority], query)
      query = filter_by(:id, args[:id], query)
      query
    end

    def filter_by_category(value, query)
      return query unless value

      query.where(market_templates: { category: value })
    end

    def filter_by(field, value, query)
      return query unless value

      query.where(field => value)
    end
  end
end
