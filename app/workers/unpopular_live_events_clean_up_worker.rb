require 'sidekiq-scheduler'

class UnpopularLiveEventsCleanUpWorker < ApplicationWorker
  def perform
    Event
      .left_outer_joins(markets: { odds: :bets })
      .where(traded_live: true)
      .where(bets: { id: nil })
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', Time.zone.now - 24.hours)
      .delete_all
  end
end
