# frozen_string_literal: true

class CleanUpUselessOddsWorker < CleanUpBaseWorker
  DELAY_END_AT = 1.month

  def delete_query
    <<~SQL
      DELETE FROM odds WHERE odds.id IN (
        SELECT odds.id
        FROM (
          SELECT filtered_odds.id, filtered_odds.market_id
          FROM odds AS filtered_odds
          LEFT OUTER JOIN bet_legs ON bet_legs.odd_id = filtered_odds.id
          WHERE bet_legs.odd_id IS NULL AND
                filtered_odds.updated_at < '#{DELAY_END_AT.ago.to_s(:db)}'
        ) AS odds
        JOIN markets ON odds.market_id = markets.id
        JOIN events ON markets.event_id = events.id
        WHERE
          events.end_at IS NOT NULL AND
          events.end_at < '#{DELAY_END_AT.ago.to_s(:db)}' AND
          markets.status = '#{Market::SETTLED}'
        LIMIT #{BATCH_SIZE}
      )
    SQL
  end
end
