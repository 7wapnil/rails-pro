module StateMachines
  module CustomerBonusStateMachine
    extend ActiveSupport::Concern

    STATUSES = {
      pending: PENDING = 'pending',
      active: ACTIVE = 'active',
      cancelled_manually: CANCELLED_MANUALLY = 'cancelled_manually',
      expired_by_date: EXPIRED_BY_DATE = 'expired_by_date',
      converted: CONVERTED = 'converted',
      withdrawn: WITHDRAWN = 'withdrawn'
    }.freeze

    EXPIRED_STATUSES = [CANCELLED_MANUALLY, EXPIRED_BY_DATE, CONVERTED, WITHDRAWN]

    DEFAULT_STATUS = PENDING

    included do
      enum status: STATUSES

      include AASM

      aasm column: :status, enum: true do
        state :pending, initial: true
        state :active
        state :cancelled_manually
        state :expired_by_date
        state :converted
        state :withdrawn

        event :activate do
          transitions from: :pending,
                      to: :active
        end

        event :expire_by_date do
          transitions from: :active,
                      to: :expired_by_date
        end

        event :manual_cancel do
          transitions from: :active,
                      to: :cancelled_manually
        end

        event :withdraw do
          transitions from: :active,
                      to: :withdrawn
        end
      end

      validates :status, presence: true
    end
  end
end
