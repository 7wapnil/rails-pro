require 'sidekiq-scheduler'

class UnpopularPreLiveEventsCleanUpWorker
  include Sidekiq::Worker

  def perform
    Event
      .left_outer_joins(markets: { odds: :bets })
      .where(traded_live: false)
      .where(bets: { id: nil })
      .where('events.start_at IS NOT NULL')
      .where('events.start_at < ?', Time.zone.now - 24.hours)
      .delete_all
  end
end
