# frozen_string_literal: true

module StateMachines
  module BetStateMachine
    extend ActiveSupport::Concern

    INITIAL                     = 'initial'
    SENT_TO_INTERNAL_VALIDATION = 'sent_to_internal_validation'
    VALIDATED_INTERNALLY        = 'validated_internally'
    SENT_TO_EXTERNAL_VALIDATION = 'sent_to_external_validation'
    ACCEPTED                    = 'accepted'
    CANCELLED                   = 'cancelled'
    SETTLED                     = 'settled'
    REJECTED                    = 'rejected'
    FAILED                      = 'failed'

    BET_STATUSES = {
      initial:                     INITIAL,
      sent_to_internal_validation: SENT_TO_INTERNAL_VALIDATION,
      validated_internally:        VALIDATED_INTERNALLY,
      sent_to_external_validation: SENT_TO_EXTERNAL_VALIDATION,
      accepted:                    ACCEPTED,
      cancelled:                   CANCELLED,
      settled:                     SETTLED,
      rejected:                    REJECTED,
      failed:                      FAILED
    }.freeze

    BET_SETTLEMENT_STATUSES = {
      lost: LOST = 'lost',
      won:  WON  = 'won'
    }.freeze

    included do
      enum status: BET_STATUSES
      enum settlement_status: BET_SETTLEMENT_STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :initial, initial: true
        state :sent_to_internal_validation
        state :validated_internally
        state :sent_to_external_validation
        state :accepted
        state :rejected
        state :cancelled
        state :failed
        state :settled

        event :send_to_internal_validation do
          transitions from: :initial,
                      to: :sent_to_internal_validation
        end

        event :finish_internal_validation_successfully do
          transitions from: :sent_to_internal_validation,
                      to: :validated_internally
        end

        event :send_to_external_validation,
              after: :send_single_bet_to_external_validation do
          transitions from: :validated_internally,
                      to: :sent_to_external_validation
        end

        event :finish_external_validation_with_acceptance,
              after: :on_successfull_bet_placement do
          transitions from: :sent_to_external_validation,
                      to: :accepted
        end

        event :finish_external_validation_with_rejection do
          transitions from: :sent_to_external_validation,
                      to: :rejected
        end

        event :register_failure do
          transitions from: :sent_to_internal_validation,
                      to: :failed,
                      after: proc { |msg| update(message: msg) }
        end

        event :settle do
          transitions from: :accepted,
                      to: :settled,
                      after: proc { |args| settle_as(args) }
        end
      end

      def settle_as(settlement_status:, void_factor:)
        update(
          status: :settled,
          settlement_status: settlement_status,
          void_factor: void_factor
        )
      end

      def send_single_bet_to_external_validation
        BetExternalValidation::Service.call(self)
      end

      def on_successfull_bet_placement
        entry.confirmed_at = Time.zone.now
        WebSocket::Client.instance.emit(WebSocket::Signals::BET_PLACED,
                                        id: id.to_s)
      end
    end
  end
end
