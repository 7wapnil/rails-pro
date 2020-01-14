# frozen_string_literal: true

module EveryMatrix
  module StateMachines
    module TransactionStateMachine
      extend ActiveSupport::Concern

      STATUSES = {
        finished: FINISHED = 'finished',
        pending_bonus_loss: PENDING_BONUS_LOSS = 'pending_bonus_loss'
      }.freeze

      DEFAULT_STATUS = FINISHED

      included do
        enum status: STATUSES

        include AASM

        aasm column: :status, enum: true do
          state :finished, initial: true
          state :pending_bonus_loss

          event :finish do
            transitions from: %i[pending_bonus_loss],
                        to: :finished
          end
        end
      end
    end
  end
end
