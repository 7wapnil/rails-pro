module Radar
  class Producer < ApplicationRecord
    self.table_name = 'radar_providers'

    has_many :events

    UNSUBSCRIBED_STATES = {
      unsubscribed: UNSUBSCRIBED = 'unsubscribed'.freeze
    }.freeze

    SUBSCRIBED_STATES = {
      recovering: RECOVERING = 'recovering'.freeze,
      healthy: HEALTHY = 'healthy'.freeze
    }.freeze

    STATES = UNSUBSCRIBED_STATES.merge(SUBSCRIBED_STATES)

    enum state: STATES

    def self.last_recovery_call_at
      Radar::Producer.all.pluck(:recover_requested_at)&.compact&.sort&.first
    end

    def live?
      code == :liveodds
    end

    def subscribed?
      SUBSCRIBED_STATES.value?(state)
    end

    def unsubscribe_expired!
      return false if last_successful_subscribed_at > 60.seconds.ago

      unsubscribe!
    end

    def unsubscribe!
      return false if unsubscribed?

      unsubscribed!
    end

    def subscribed!(subscribed_at: Time.zone.now)
      recover! unless subscribed?
      avoid_timestamp_override =
        last_successful_subscribed_at &&
        last_successful_subscribed_at >= subscribed_at
      return false if avoid_timestamp_override

      update(last_successful_subscribed_at: subscribed_at)
    end

    def recover!
      return unless unsubscribed?

      OddsFeed::Radar::SubscriptionRecovery.call(product: self)
      update(state: RECOVERING)
    end

    def recovery_completed!
      healthy!
    end
  end
end
