# frozen_string_literal: true

class CleanUpUselessOddsWorker < CleanUpBaseWorker
  DELAY_END_AT = 1.month

  def delete_query
    <<~SQL
      DELETE FROM odds WHERE odds.id IN (
        SELECT odds.id
        FROM events
        JOIN markets ON markets.event_id = events.id
        JOIN odds ON odds.market_id = markets.id
        WHERE
          end_at IS NOT NULL AND
          end_at < '#{DELAY_END_AT.ago.to_s(:db)}' AND
          markets.status = 'settled' AND
          odds.updated_at < '#{DELAY_END_AT.ago.to_s(:db)}' AND
          odds.id NOT IN (
            SELECT DISTINCT odds.id FROM odds
            JOIN bet_legs ON bet_legs.odd_id = odds.id
          )
        LIMIT #{BATCH_SIZE}
      )
    SQL
  end
end
