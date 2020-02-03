# frozen_string_literal: true

class CleanUpUselessMarketsWorker < CleanUpBaseWorker
  DELAY_END_AT = 1.month

  def delete_query
    <<~SQL
      DELETE FROM markets WHERE markets.id IN (
        SELECT markets.id
        FROM events
        JOIN markets ON markets.event_id = events.id
        WHERE
          end_at IS NOT NULL AND
          end_at < '#{DELAY_END_AT.ago.to_s(:db)}' AND
          markets.status = 'settled' AND
          markets.updated_at < '#{DELAY_END_AT.ago.to_s(:db)}' AND
          markets.id NOT IN (
            SELECT DISTINCT markets.id FROM markets
            JOIN odds ON odds.market_id = markets.id
            JOIN bet_legs ON bet_legs.odd_id = odds.id
          )
        LIMIT #{BATCH_SIZE}
      )
    SQL
  end
end
