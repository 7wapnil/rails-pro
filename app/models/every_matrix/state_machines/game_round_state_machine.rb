# frozen_string_literal: true

module EveryMatrix
  module StateMachines
    module GameRoundStateMachine
      extend ActiveSupport::Concern

      STATUSES = {
        pending: PENDING = 'pending',
        won: WON = 'won',
        lost: LOST = 'lost',
        rolled_back: ROLLED_BACK = 'rolled_back',
        expired: EXPIRED = 'expired'
      }.freeze

      FINISHED_STATUSES = [
        WON,
        LOST,
        ROLLED_BACK,
        EXPIRED
      ].freeze

      DEFAULT_STATUS = PENDING

      included do
        enum status: STATUSES

        scope :finished, -> { where(status: FINISHED_STATUSES) }

        include AASM

        aasm column: :status, enum: true do
          state :pending, initial: true
          state :won
          state :lost
          state :rolled_back
          state :expired

          event :win do
            transitions from: PENDING,
                        to: :won
          end

          event :lose do
            transitions from: PENDING,
                        to: :lost
          end

          event :rollback do
            transitions from: PENDING,
                        to: :rolled_back
          end

          event :expire do
            transitions from: PENDING,
                        to: :expired
          end
        end
      end
    end
  end
end
