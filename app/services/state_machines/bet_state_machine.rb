module StateMachines
  module BetStateMachine
    extend ActiveSupport::Concern

    BET_STATUSES = {
      pending: 0,
      succeeded: 1,
      failed: 2,
      settled: 3,
      cancelled: 4
    }.freeze

    included do
      enum status: BET_STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :pending, initial: true
        state :succeeded
        state :failed
        state :settled
        state :cancelled

        event :failure do
          transitions from: :pending,
                      to: :failed,
                      after: proc { |msg| update(message: msg) }
        end

        event :settle do
          transitions from: :succeeded,
                      to: :settled,
                      after: proc { |args| update_attributes(args) }
        end
      end
    end
  end
end
