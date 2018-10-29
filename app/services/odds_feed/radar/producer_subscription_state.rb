module OddsFeed
  module Radar
    class ProducerSubscriptionState
      SUBSCRIPTION_REPORT_KEY_PREFIX =
        'radar:last_producer_subscription_report:'.freeze

      attr_accessor :persistence_provider

      def initialize(producer_id, persistence_provider = Rails.cache)
        @producer_id = producer_id
        @persistence_provider = persistence_provider
      end

      def subscribed!(reported_at)
        timestamp = reported_at.to_i
        timestamp_expired = last_subscribed_reported_timestamp > timestamp
        return if timestamp_expired

        store_last_subscribed_at_timestamp(timestamp)
      end

      def recover_subscription!
        OddsFeed::Radar::SubscriptionRecovery
          .call(product_id: @producer_id, start_at: available_recovery_time)
      end

      private

      def available_recovery_time
        timestamp = last_subscribed_reported_timestamp
        return nil if Time.zone.at(timestamp) < 72.hours.ago

        timestamp
      end

      def last_subscribed_reported_timestamp
        persistence_provider.read(last_subscribed_at_key).to_i
      end

      def store_last_subscribed_at_timestamp(timestamp)
        persistence_provider.write(last_subscribed_at_key, timestamp)
      end

      def last_subscribed_at_key
        SUBSCRIPTION_REPORT_KEY_PREFIX + @producer_id.to_s
      end
    end
  end
end
