require 'sidekiq-scheduler'

class UnpopularEventsCleanWorker
  include Sidekiq::Worker

  def perform
    Event
      .left_outer_joins(markets: { odds: :bets })
      .where(bets: { id: nil })
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', DateTime.current)
      .delete_all
  end
end
