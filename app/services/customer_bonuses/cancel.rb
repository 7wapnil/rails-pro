# frozen_string_literal: true

module CustomerBonuses
  class Cancel < ApplicationService
    delegate :wallet, to: :customer_bonus, allow_nil: true
    delegate :bonus_balance, to: :wallet, allow_nil: true

    def initialize(bonus:, **params)
      @customer_bonus = bonus
      @user = params[:user]
    end

    def call
      return unless customer_bonus
      return customer_bonus if customer_bonus.deleted_at

      deactivate_bonus!
      confiscate_bonus_money! if positive_bonus_balance?

      log_deactivation
    end

    protected

    attr_accessor :customer_bonus, :user

    private

    def deactivate_bonus!
      customer_bonus.transaction do
        customer_bonus.cancel!
        customer_bonus.destroy!
      end
    end

    def confiscate_bonus_money!
      request = EntryRequests::Factories::BonusChange
                .call(wallet: wallet, amount: -bonus_balance.amount)
      EntryRequests::BonusChangeWorker.perform_async(request.id)
    end

    def positive_bonus_balance?
      bonus_balance&.amount.to_f.positive?
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
