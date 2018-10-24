require 'sidekiq-scheduler'

class UnpopularEventsCleaner
  include Sidekiq::Worker

  def perform
    Event
      .where('events.end_at IS NOT NULL')
      .where('events.end_at < ?', DateTime.current)
      .where(
        'events.id NOT IN (?)',
        Bet
          .joins(market: :event)
          .select('events.id')
          .each(&:id)
      )
      .delete_all
  end
end
