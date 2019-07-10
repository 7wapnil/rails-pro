# frozen_string_literal: true

module CustomerBonuses
  class Deactivate < ApplicationService
    delegate :wallet, to: :customer_bonus, allow_nil: true
    delegate :bonus_balance, to: :wallet, allow_nil: true

    ACTIONS = [
      EXPIRE = :expire!,
      CANCEL = :cancel!,
      LOSE = :lose!
    ].freeze

    def initialize(bonus:, action:, **params)
      @customer_bonus = bonus
      @action = action
      @user = params[:user]
    end

    def call
      return unless customer_bonus

      validate_action!

      deactivate_bonus!
      confiscate_bonus_money! if positive_bonus_balance?

      log_deactivation
    end

    protected

    attr_accessor :customer_bonus, :action, :user

    private

    def validate_action!
      valid = ACTIONS.include?(action)
      error_message = 'Action can be either :cancel! or :expire!'
      raise ArgumentError, error_message unless valid
    end

    def deactivate_bonus!
      return unless customer_bonus.active?

      customer_bonus.send(action)
    end

    def confiscate_bonus_money!
      request = EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: -bonus_balance.amount
      )

      EntryRequests::BonusChangeWorker.perform_async(request.id)
    end

    def positive_bonus_balance?
      bonus_balance.amount.positive?
    end

    def log_deactivation
      return user_log(user, customer_bonus.customer) if user

      customer_log(customer_bonus.customer)
    end

    def user_log(user, customer)
      user.log_event(:customer_bonus_deactivated, customer_bonus, customer)
    end

    def customer_log(user)
      user.log_event(:customer_bonus_deactivated, customer_bonus)
    end
  end
end
