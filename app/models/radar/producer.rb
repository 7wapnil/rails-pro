module Radar
  class Producer < ApplicationRecord
    LIVE_PROVIDER_ID = 1
    LIVE_PROVIDER_CODE = 'liveodds'.freeze
    PREMATCH_PROVIDER_ID = 3
    PREMATCH_PROVIDER_CODE = 'pre'.freeze
    RECOVERY_WAIT_TIME_IN_SECONDS = 10

    self.table_name = 'radar_providers'

    after_commit :notify_application

    has_many :events

    HEARTBEAT_EXPIRATION_TIME_IN_SECONDS = 15

    UNSUBSCRIBED_STATES = {
      unsubscribed: UNSUBSCRIBED = 'unsubscribed'.freeze
    }.freeze

    SUBSCRIBED_STATES = {
      recovering: RECOVERING = 'recovering'.freeze,
      healthy:    HEALTHY    = 'healthy'.freeze
    }.freeze

    STATES = UNSUBSCRIBED_STATES.merge(SUBSCRIBED_STATES)

    enum state: STATES

    class << self
      def last_recovery_call_at
        Radar::Producer
          .order('recover_requested_at DESC NULLS LAST')
          .first&.recover_requested_at
      end

      def live
        find_by(code: LIVE_PROVIDER_CODE)
      end

      def prematch
        find_by(code: PREMATCH_PROVIDER_CODE)
      end
    end

    def live?
      code == LIVE_PROVIDER_CODE
    end

    def prematch?
      code == PREMATCH_PROVIDER_CODE
    end

    def subscribed?
      SUBSCRIBED_STATES.value?(state)
    end

    def unsubscribe_expired!
      expired? ? unsubscribe! : false
    end

    def unsubscribe!(with_recovery: false)
      return false if unsubscribed?
      return false if recovery_requested_recently?

      unsubscribed!
      clean_recovery_data
      recover! if with_recovery
    end

    def subscribed!(subscribed_at: Time.zone.now)
      recover! unless subscribed?
      return false unless timestamp_update_required(subscribed_at)

      update(last_successful_subscribed_at: subscribed_at)
    end

    def recover!
      return unless unsubscribed?

      recovering! if OddsFeed::Radar::SubscriptionRecovery.call(product: self)
    end

    def recovery_completed!
      healthy!
    end

    private

    def recovery_requested_recently?
      recover_requested_at >= RECOVERY_WAIT_TIME_IN_SECONDS.second.ago
    end

    def clean_recovery_data
      update(recovery_snapshot_id: nil,
             recover_requested_at: nil,
             recovery_node_id: nil)
    end

    def expired?
      last_successful_subscribed_at <=
        HEARTBEAT_EXPIRATION_TIME_IN_SECONDS.seconds.ago
    end

    def timestamp_update_required(subscribed_at)
      !last_successful_subscribed_at ||
        last_successful_subscribed_at < subscribed_at
    end

    def notify_application
      return unless saved_change_to_state?

      WebSocket::Client.instance.trigger_provider_update(self)
    end
  end
end
