require 'sidekiq-scheduler'

class UnpopularEventsCleanUpWorker < ApplicationWorker
  def perform
    Event
      .left_outer_joins(markets: { odds: :bet_legs })
      .where(bet_legs: { id: nil })
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', Time.zone.now - 24.hours)
      .delete_all
  end
end
