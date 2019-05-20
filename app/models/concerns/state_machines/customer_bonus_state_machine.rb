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
      expired: EXPIRED = 'expired'
    }.freeze

    DEFAULT_STATUS = INITIAL
    USED_STATUSES = [CANCELLED, COMPLETED, EXPIRED].freeze

    included do
      enum status: STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :initial, initial: true
        state :failed
        state :active
        state :cancelled
        state :completed
        state :expired

        event :activate do
          transitions from: :initial,
                      to: :active
        end

        event :fail do
          transitions from: :initial,
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
      end

      validates :status, presence: true
    end
  end
end
