module Radar
  class Producer < ApplicationRecord
    self.table_name = 'radar_providers'

    has_many :events

    STATES = {
      healthy: HEALTHY = 'healthy'.freeze,
      unsubscribed: UNSUBSCRIBED = 'unsubscribed'.freeze,
      recovering: RECOVERING = 'healthy'.freeze
    }.freeze

    enum state: STATES

    def self.last_recovery_call_at
      Radar::Producer.all.pluck(:recover_requested_at)&.compact&.sort&.first
    end

    def live?
      code == :liveodds
    end

    def subscribed?
      [HEALTHY, RECOVERING].include? state
    end

    def unsubscribe_expired!
      return false if last_successful_subscribed_at < 60.seconds.ago

      unsubscribe!
    end

    def unsubscribe!
      return false unless subscribed?

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

      OddsFeed::Radar::SubscriptionRecovery.call(product_id: id)
      update(state: RECOVERING)
    end

    def recovery_completed!
      healthy!
    end
  end
end
