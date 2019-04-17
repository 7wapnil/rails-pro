require 'sidekiq-scheduler'

class UnpopularEventsCleanUpWorker < ApplicationWorker
  def perform
    Event
      .left_outer_joins(markets: { odds: :bets })
      .where(bets: { id: nil })
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', Time.zone.now - 24.hours)
      .delete_all
  end
end
