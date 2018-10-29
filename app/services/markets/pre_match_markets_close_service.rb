module Markets
  class PreMatchMarketsCloseService < ApplicationService
    UPCOMING_EVENT_MINUTES_DELAY =
      ENV.fetch('UPCOMING_EVENT_MINUTES_DELAY') { 5 }.to_i

    def call
      Market
        .joins(:event)
        .where.not(status: :suspended)
        .where(events: { traded_live: false })
        .where(
          'events.start_at < ?',
          Time.zone.now + UPCOMING_EVENT_MINUTES_DELAY.minutes
        )
        .update_all(status: :suspended)
    end
  end
end
