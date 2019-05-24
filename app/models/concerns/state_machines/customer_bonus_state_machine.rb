# frozen_string_literal: true

module StateMachines
  module CustomerBonusStateMachine
    extend ActiveSupport::Concern

    STATUSES = {
      initial: INITIAL = 'initial',
      failed: FAILED = 'failed',
      active: ACTIVE = 'active',
      cancelled: CANCELLED = 'cancelled',
      completed: COMPLETED = 'completed',
      lost: LOST = 'lost',
      expired: EXPIRED = 'expired'
    }.freeze

    DEFAULT_STATUS = INITIAL
    USED_STATUSES = [CANCELLED, COMPLETED, LOST, EXPIRED].freeze
    SYSTEM_STATUSES = [INITIAL, FAILED].freeze

    included do
      enum status: STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :initial, initial: true
        state :failed
        state :active
        state :cancelled
        state :completed
        state :lost
        state :expired

        event :activate do
          transitions from: :initial,
                      to: :active,
                      after: :assign_balance_entry
        end

        event :fail do
          transitions from: %i[initial failed expired],
                      to: :failed
        end

        event :cancel do
          transitions from: :active,
                      to: :cancelled
        end

        event :complete do
          transitions from: :active,
                      to: :completed
        end

        event :expire do
          transitions from: :active,
                      to: :expired
        end

        event :lose do
          transitions from: :active,
                      to: :lost
        end
      end

      validates :status, presence: true

      private

      def assign_balance_entry(balance_entry)
        update(balance_entry: balance_entry)
      end
    end
  end
end
