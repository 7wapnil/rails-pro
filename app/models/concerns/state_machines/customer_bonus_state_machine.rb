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

        after_all_events :log_transition_success
        error_on_all_events :log_transition_error

        event :activate do
          transitions from: :initial,
                      to: :active,
                      after: %i[assign_balance_entry set_activated_at]
        end

        event :fail do
          transitions from: %i[initial failed expired],
                      to: :failed
        end

        event :cancel do
          transitions from: :active,
                      to: :cancelled,
                      after: :set_deactivated_at
        end

        event :complete do
          transitions from: :active,
                      to: :completed,
                      after: :set_deactivated_at
        end

        event :expire do
          transitions from: %i[active initial],
                      to: :expired,
                      after: :set_deactivated_at
        end

        event :lose do
          transitions from: :active,
                      to: :lost,
                      after: :set_deactivated_at
        end
      end

      validates :status, presence: true

      private

      def assign_balance_entry(balance_entry)
        update(balance_entry: balance_entry)
      end

      def set_activated_at
        update(activated_at: Time.zone.now)
      end

      def set_deactivated_at
        update(deactivated_at: Time.zone.now)
      end

      def log_transition_success
        Rails.logger.info(
          message: 'CustomerBonus status changed',
          from_state: aasm.from_state,
          to_state: aasm.to_state,
          id: id,
          customer_id: customer_id
        )
      end

      def log_transition_error(error)
        Rails.logger.error(
          message: 'CustomerBonus status change failed',
          from_state: error.originating_state,
          to_state: aasm.to_state,
          id: id,
          customer_id: customer_id,
          error_object: error
        )
      end
    end
  end
end
