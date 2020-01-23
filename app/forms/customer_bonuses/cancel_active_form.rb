# frozen_string_literal: true

module CustomerBonuses
  class CancelActiveForm
    include ActiveModel::Model

    attr_reader :current_customer

    validate :customer_has_active_bonus
    validate :no_pending_bets

    def initialize(current_customer:)
      @current_customer = current_customer
    end

    def submit!
      validate!
      CustomerBonuses::Deactivate.call(
        bonus: current_customer.active_bonus,
        action: CustomerBonuses::Deactivate::CANCEL,
        user: current_customer
      )
    end

    def validate!
      return if valid?

      raise CustomerBonuses::ActiveCancellationError, displayed_error
    end

    private

    def no_pending_bets
      return if !current_customer || no_pending_bets_with_bonus?

      errors.add(
        :base,
        I18n.t('errors.messages.customer_should_have_no_pending_bets')
      )
    end

    def no_pending_bets_with_bonus?
      current_customer
        .bets
        .pending
        .joins(:entry_requests)
        .where.not(entry_requests: { bonus_amount: 0 })
        .none?
    end

    def customer_has_active_bonus
      return if current_customer.active_bonus

      errors.add(
        :base,
        I18n.t('errors.messages.customer_should_have_active_bonus')
      )
    end

    def displayed_error
      errors.first[1]
    end
  end
end
