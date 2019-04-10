# frozen_string_literal: true

module StateMachines
  module MarketStateMachine
    extend ActiveSupport::Concern

    STATUSES = {
      inactive: INACTIVE = 'inactive',
      active: ACTIVE = 'active',
      suspended: SUSPENDED = 'suspended',
      cancelled: CANCELLED = 'cancelled',
      settled: SETTLED = 'settled',
      handed_over: HANDED_OVER = 'handed_over'
    }.freeze

    DISPLAYED_STATUSES = [ACTIVE, SUSPENDED].freeze
    DEFAULT_STATUS = ACTIVE

    included do
      enum status: STATUSES
      enum previous_status: STATUSES, _prefix: true

      validates :status, presence: true
      validates_with MarketStateValidator, restrictions: [
        %i[settled active],
        %i[settled inactive],
        %i[settled suspended],
        %i[cancelled active],
        %i[cancelled inactive],
        %i[cancelled suspended],
        %i[cancelled settled]
      ]

      before_update :snapshot_status!, if: :status_changed?

      def rollback_status!(persist: true)
        Markets::StatusTransition.call(market: self, persist: persist)
      end

      private

      def snapshot_status!
        Markets::StatusTransition.call(market: self, status: status)
      end
    end
  end
end
