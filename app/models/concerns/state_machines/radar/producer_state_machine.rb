# frozen_string_literal: true

module StateMachines
  module Radar
    module ProducerStateMachine
      extend ActiveSupport::Concern

      SUBSCRIBED_STATES = {
        recovering: RECOVERING = 'recovering',
        healthy: HEALTHY = 'healthy'
      }.freeze

      STATES = {
        unsubscribed: UNSUBSCRIBED = 'unsubscribed',
        **SUBSCRIBED_STATES
      }.freeze

      included do
        include AASM

        enum state: STATES

        after_commit :notify_application, if: :saved_change_to_state?

        aasm column: :state, enum: true do
          state :unsubscribed, initial: true
          state :recovering
          state :healthy

          after_all_events :log_transition_success
          error_on_all_events :log_transition_error!

          event :register_disconnection do
            transitions from: %i[recovering healthy],
                        to: :unsubscribed,
                        after: :register_disconnection_time
          end

          event :initiate_recovery do
            transitions from: %i[unsubscribed recovering healthy],
                        to: :recovering,
                        after: :snapshot_recovery_info
          end

          event :complete_recovery do
            transitions from: :recovering,
                        to: :healthy,
                        after: :clear_recovery_info
          end

          event :skip_recovery do
            transitions from: %i[unsubscribed recovering healthy],
                        to: :healthy,
                        after: :skip_snapshot_recovery
          end
        end

        def subscribed?
          SUBSCRIBED_STATES.value?(state)
        end

        private

        def notify_application
          WebSocket::Client.instance.trigger_provider_update(self)
        end

        def log_transition_success
          Rails.logger.info(message: 'Producer state changed',
                            from_state: aasm.from_state,
                            to_state: aasm.to_state || aasm.current_state,
                            last_message_timestamp: last_message_timestamp,
                            **transition_log_attributes)
        end

        def log_transition_error!(error)
          Rails.logger.error(message: 'Producer state cannot be changed',
                             from_state: error.originating_state,
                             to_state: aasm.to_state || aasm.current_state,
                             error_object: error,
                             **transition_log_attributes)

          raise error
        end

        def transition_log_attributes
          {
            producer_id: id,
            code: code,
            last_subscribed_at: last_subscribed_at,
            recovery_requested_at: recovery_requested_at,
            recovery_snapshot_id: recovery_snapshot_id,
            recovery_node_id: recovery_node_id,
            last_disconnected_at: last_disconnected_at
          }
        end

        def last_message_timestamp
          last_subscribed_at
            &.to_datetime
            &.strftime(::OddsFeed::Radar::Timestampable::TIMESTAMP_FORMAT)
        end

        def register_disconnection_time(last_subscribed_at:)
          update(last_disconnected_at: last_subscribed_at)
        end

        def snapshot_recovery_info(requested_at:, snapshot_id:, node_id:)
          update(recovery_requested_at: requested_at,
                 recovery_snapshot_id: snapshot_id,
                 recovery_node_id: node_id)
        end

        def clear_recovery_info
          update(recovery_requested_at: nil,
                 recovery_snapshot_id: nil,
                 recovery_node_id: nil,
                 last_disconnected_at: nil)
        end

        def skip_snapshot_recovery(requested_at: Time.zone.now)
          update(last_subscribed_at: requested_at,
                 last_disconnected_at: nil,
                 recovery_requested_at: nil,
                 recovery_snapshot_id: nil,
                 recovery_node_id: nil)
        end
      end
    end
  end
end
