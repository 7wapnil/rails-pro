module StateMachines
  module BetStateMachine
    extend ActiveSupport::Concern

    BET_STATUSES = {
      initial: 0,
      sent_to_internal_validation: 5,
      validated_internally: 6,
      sent_to_external_validation: 7,
      accepted: 1,
      cancelled: 4,
      settled: 3,
      rejected: 9,
      failed: 2
    }.freeze

    included do
      enum status: BET_STATUSES

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

        event :register_failure do
          transitions from: :sent_to_internal_validation,
                      to: :failed,
                      after: proc { |msg| update(message: msg) }
        end

        event :settle do
          transitions from: :accepted,
                      to: :settled,
                      after: proc { |args| update_attributes(args) }
        end
      end

      def send_single_bet_to_external_validation
        request = Mts::Messages::ValidationRequest
                  .new([self])
        response = Mts::SubmissionPublisher
                   .publish!(request)
        return false if response == false
        update(validation_ticket_id: request.ticket_id,
               validation_ticket_sent_at: Time.zone.now)
      end
    end
  end
end
