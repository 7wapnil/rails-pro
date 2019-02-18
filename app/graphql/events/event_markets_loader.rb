module Events
  class EventMarketsLoader < BatchLoader
    def perform(event_ids)
      scope(event_ids).each { |record| fulfill(record.event_id, record) }

      event_ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
    end

    protected

    def scope(event_ids)
      model.joins(:odds).where(id: market_ids(event_ids))
    end

    def market_ids(event_ids) # rubocop:disable Metrics/MethodLength
      Event
        .select('markets.id AS market_id')
        .joins(
          <<~SQL
            INNER JOIN markets ON markets.id = (
              SELECT markets.id
              FROM markets
              INNER JOIN odds
              ON odds.market_id = markets.id
              WHERE markets.event_id = events.id AND
                    markets.visible = TRUE AND
                    event_id IN (#{event_ids.join(', ')})
              ORDER BY priority ASC
              LIMIT 1
            )
          SQL
        )
        .where(id: event_ids)
    end
  end
end
