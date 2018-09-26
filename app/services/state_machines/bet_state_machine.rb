module StateMachines
  module BetStateMachine
    extend ActiveSupport::Concern

    BET_STATUSES = {
      initial: 0,
      pending_internal_validation: 5,
      internally_valid: 6,
      pending_external_validation: 7,
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
        state :pending_internal_validation
        state :internally_valid
        state :pending_external_validation
        state :accepted
        state :rejected
        state :cancelled
        state :failed
        state :settled

        event :validate_internally do
          transitions from: :initial,
                      to: :validate_internally
        end

        event :internal_validation_success do
          transitions from: :validate_internally,
                      to: :internally_valid
        end

        event :validate_externally do
          transitions from: :internally_valid,
                      to: :pending_external_validation
        end

        event :failure do
          transitions from: :initial,
                      to: :failed,
                      after: proc { |msg| update(message: msg) }
        end

        event :settle do
          transitions from: :accepted,
                      to: :settled,
                      after: proc { |args| update_attributes(args) }
        end
      end
    end
  end
end
