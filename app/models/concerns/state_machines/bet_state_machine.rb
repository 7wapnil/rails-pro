# frozen_string_literal: true

module StateMachines
  module BetStateMachine # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    INITIAL = 'initial'
    SENT_TO_INTERNAL_VALIDATION = 'sent_to_internal_validation'
    VALIDATED_INTERNALLY = 'validated_internally'
    SENT_TO_EXTERNAL_VALIDATION = 'sent_to_external_validation'
    ACCEPTED = 'accepted'
    PENDING_CANCELLATION = 'pending_cancellation'
    PENDING_MANUAL_CANCELLATION = 'pending_manual_cancellation'
    CANCELLED = 'cancelled'
    CANCELLED_BY_SYSTEM = 'cancelled_by_system'
    PENDING_MANUAL_SETTLEMENT = 'pending_manual_settlement'
    SETTLED = 'settled'
    REJECTED = 'rejected'
    FAILED = 'failed'
    MANUALLY_SETTLED = 'manually_settled'

    BET_STATUSES = {
      initial: INITIAL,
      sent_to_internal_validation: SENT_TO_INTERNAL_VALIDATION,
      validated_internally: VALIDATED_INTERNALLY,
      sent_to_external_validation: SENT_TO_EXTERNAL_VALIDATION,
      accepted: ACCEPTED,
      pending_cancellation: PENDING_CANCELLATION,
      pending_manual_cancellation: PENDING_MANUAL_CANCELLATION,
      cancelled: CANCELLED,
      cancelled_by_system: CANCELLED_BY_SYSTEM,
      pending_manual_settlement: PENDING_MANUAL_SETTLEMENT,
      settled: SETTLED,
      rejected: REJECTED,
      failed: FAILED,
      manually_settled: MANUALLY_SETTLED
    }.freeze

    BET_SETTLEMENT_STATUSES = {
      lost: LOST = 'lost',
      won: WON = 'won',
      voided: VOIDED = 'voided'
    }.freeze

    PENDING_STATUSES_MASK = [
      SENT_TO_INTERNAL_VALIDATION,
      VALIDATED_INTERNALLY,
      SENT_TO_EXTERNAL_VALIDATION,
      ACCEPTED,
      PENDING_MANUAL_SETTLEMENT
    ].freeze

    CANCELLED_STATUSES_MASK = [
      PENDING_CANCELLATION,
      PENDING_MANUAL_CANCELLATION,
      CANCELLED,
      CANCELLED_BY_SYSTEM
    ].freeze

    SETTLED_STATUSES_MASK = [
      SETTLED,
      MANUALLY_SETTLED
    ].freeze

    included do
      enum status: BET_STATUSES
      enum settlement_status: BET_SETTLEMENT_STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :initial, initial: true
        state :sent_to_internal_validation
        state :validated_internally
        state :sent_to_external_validation
        state :accepted, after_enter: :update_summary
        state :rejected
        state :pending_cancellation
        state :pending_manual_cancellation
        state :cancelled
        state :cancelled_by_system
        state :failed
        state :pending_manual_settlement
        state :settled
        state :manually_settled

        after_all_events :log_transition_success
        error_on_all_events :log_transition_error

        event :send_to_internal_validation do
          transitions from: :initial,
                      to: :sent_to_internal_validation
        end

        event :finish_internal_validation_successfully do
          transitions from: :sent_to_internal_validation,
                      to: :validated_internally
        end

        event :send_to_external_validation,
              after: :request_external_validation do
          transitions from: :validated_internally,
                      to: :sent_to_external_validation
        end

        event :finish_external_validation_with_acceptance,
              after: :on_successful_placement do
          transitions from: :sent_to_external_validation,
                      to: :accepted
        end

        event :finish_external_validation_with_rejection do
          transitions from: :sent_to_external_validation,
                      to: :rejected,
                      after: :update_error_notification
        end

        event :timed_out_external_validation do
          transitions from: :sent_to_external_validation,
                      to: :pending_cancellation
        end

        event :finish_external_cancellation_with_rejection do
          transitions from: %i[pending_cancellation
                               sent_to_external_validation
                               accepted
                               rejected
                               pending_manual_settlement],
                      to: :pending_manual_cancellation,
                      after: :update_error_notification
        end

        event :finish_external_cancellation_with_acceptance do
          transitions from: :pending_cancellation,
                      to: :cancelled
        end

        event :register_failure do
          transitions from: %i[initial
                               sent_to_internal_validation
                               sent_to_external_validation
                               pending_manual_settlement],
                      to: :failed,
                      after: :update_error_notification
        end

        event :settle do
          transitions from: %i[accepted pending_manual_settlement],
                      to: :settled,
                      after: proc { |args| settle_as(args) }
        end

        event :send_to_manual_settlement do
          transitions from: %i[accepted settled voided],
                      to: :pending_manual_settlement,
                      after: :update_error_notification
        end

        event :rollback_settlement do
          transitions from: %i[settled pending_manual_settlement],
                      to: :accepted,
                      after: :reset_settlement_info
        end

        event :cancel_by_system do
          transitions from: %i[accepted settled pending_manual_settlement],
                      to: :cancelled_by_system,
                      after: :reset_settlement_info
        end

        event :rollback_system_cancellation_with_acceptance do
          transitions from: :cancelled_by_system,
                      to: :accepted
        end

        event :rollback_system_cancellation_with_settlement do
          transitions from: :cancelled_by_system,
                      to: :settled,
                      after: proc { |args| settle_as(args) }
        end

        event :cancel do
          transitions from: %i[pending_cancellation
                               sent_to_external_validation
                               accepted
                               rejected
                               pending_manual_settlement],
                      to: :cancelled
        end

        event :settle_manually do
          transitions from: BET_STATUSES.values,
                      to: :manually_settled,
                      after: proc { |args| settle_as(args) }
        end
      end

      private

      def settle_as(settlement_status:, void_factor: nil)
        update(
          settlement_status: settlement_status,
          void_factor: void_factor,
          bet_settlement_status_achieved_at: Time.zone.now
        )
      end

      def request_external_validation
        BetExternalValidation::Service.call(self)
      end

      def on_successful_placement
        entry.update(confirmed_at: Time.zone.now)
      end

      def update_notification(message, code:)
        update(notification_message: message, notification_code: code)
      end

      def update_error_notification(message, code: default_error_code)
        update_notification(message, code: code)
      end

      def default_error_code
        Bets::Notification::INTERNAL_SERVER_ERROR
      end

      def update_summary
        update_summary_customer_ids
        update_summary_wager_amounts
      end

      def update_summary_wager_amounts
        return unless placement_entry

        Customers::Summaries::BalanceUpdateWorker.perform_async(
          Date.current,
          placement_entry.id
        )
      end

      def update_summary_customer_ids
        Customers::Summaries::UpdateWorker.perform_async(
          Date.current,
          betting_customer_ids: customer_id
        )
      end

      def reset_settlement_info
        update(
          settlement_status: nil,
          void_factor: nil,
          bet_settlement_status_achieved_at: nil
        )
      end

      def log_transition_success
        Rails.logger.info(
          message: 'Bet status changed',
          from_state: aasm.from_state,
          to_state: aasm.to_state,
          bet_id: id,
          customer_id: customer_id,
          odd_id: odd_id,
          notification_message: notification_message,
          settlement_status: settlement_status,
          notification_code: notification_code
        )
      end

      def log_transition_error(error)
        Rails.logger.error(
          message: 'Bet status change failed',
          from_state: error.originating_state,
          to_state: aasm.to_state,
          bet_id: id,
          customer_id: customer_id,
          odd_id: odd_id,
          notification_message: notification_message,
          settlement_status: settlement_status,
          notification_code: notification_code,
          error_object: error
        )

        raise error
      end
    end
  end
end
