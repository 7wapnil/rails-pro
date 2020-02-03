# frozen_string_literal: true

class CleanUpUnpopularEventsWorker < CleanUpBaseWorker
  DELAY_END_AT = 24.hours

  def delete_query
    <<~SQL
      DELETE FROM events WHERE events.id IN (
        SELECT id
        FROM events
        WHERE
          id NOT IN (
            SELECT events.id
            FROM bet_legs
              JOIN odds ON odds.id = bet_legs.odd_id
              JOIN markets ON markets.id = odds.market_id
              JOIN events ON markets.event_id = events.id
          )
          AND end_at IS NOT NULL
          AND end_at < '#{DELAY_END_AT.ago.to_s(:db)}'
        LIMIT #{BATCH_SIZE}
      )
    SQL
  end
end
