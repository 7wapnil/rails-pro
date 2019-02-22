# frozen_string_literal: true

module Events
  class EventMarketsLoader < BatchLoader
    def perform(event_ids)
      scope(event_ids).each { |market| fulfill(market.event_id, market) }

      event_ids.each { |id| fulfill(id, []) unless fulfilled?(id) }
    end

    protected

    def scope(event_ids)
      model
        .preload(:active_odds)
        .where(id: market_ids(event_ids))
        .order(:priority)
    end

    def market_ids(event_ids)
      ActiveRecord::Base
        .connection
        .execute(event_limited_markets_sql(event_ids))
        .pluck('market_id')
    end

    def event_limited_markets_sql(event_ids)
      <<~SQL
        SELECT markets.id AS market_id
        FROM events, LATERAL (
          SELECT markets.id
          FROM markets
          JOIN odds
          ON odds.market_id = markets.id
          WHERE markets.event_id = events.id AND
                markets.visible IS TRUE AND
                odds.status = '#{Odd::ACTIVE}'
          GROUP BY markets.id
          ORDER BY priority ASC
          LIMIT 1
        ) markets
        WHERE events.id IN (#{event_ids.join(', ').presence || 'NULL'})
      SQL
    end
  end
end
