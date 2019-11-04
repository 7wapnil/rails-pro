# frozen_string_literal: true

module OddsFeed
  module Radar
    class AliveHandler < RadarMessageHandler
      include Producers::Recoverable

      SUBSCRIBED_STATE = '1'

      def handle
        producer.with_lock do
          populate_job_log_info!

          break if message_expired?

          subscribed? ? keep_subscription : accept_message_with_recovery
        end
      end

      private

      def populate_job_log_info!
        Thread.current[:producer_id] = producer.id
        Thread.current[:producer_subscription_state] = producer.subscribed?
        Thread.current[:message_subscription_state] = subscribed?
      end

      def producer
        @producer ||= ::Radar::Producer.find(scrap_field('product'))
      end

      def scrap_field(key)
        payload['alive'][key]
      end

      def subscribed?
        scrap_field('subscribed') == SUBSCRIBED_STATE
      end

      def message_expired?
        producer.last_subscribed_at.present? &&
          requested_at < producer.last_subscribed_at
      end

      def requested_at
        @requested_at ||= parse_timestamp(scrap_field('timestamp'))
      end

      def keep_subscription
        OddsFeed::Radar::Producers::KeepSubscription
          .call(producer: producer, requested_at: requested_at)
      end
    end
  end
end
