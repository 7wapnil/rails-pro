module CustomerBonuses
  class BetSettlementService < ApplicationService
    include JobLogger

    def initialize(bet:)
      @bet = bet
    end

    def call
      return unless customer_bonus&.active?

      recalculate_bonus_rollover
      complete_bonus unless customer_bonus.rollover_balance.positive?

      return if unsettled_bets_remaining || customer_bonus.completed?

      bonus_money_left = customer_bonus.wallet.bonus_balance&.amount

      log_job_message(:debug, message: 'checking wallet bonus balance',
                              wallet_id: customer_bonus.wallet,
                              bonus_money_left: bonus_money_left)

      lose_bonus unless bonus_money_left&.positive?
    end

    attr_reader :bet

    delegate :customer_bonus, to: :bet

    private

    def recalculate_bonus_rollover
      ::CustomerBonuses::RolloverCalculationService.call(bet: bet)
    end

    def complete_bonus
      CustomerBonuses::CompleteWorker
        .perform_async(customer_bonus: customer_bonus)
    end

    def lose_bonus
      return unless customer_bonus.active?

      # Other CustomerBonus deactivation processes
      # involve bonus balance confiscation. At this
      # point, there is nothing to confiscate.
      customer_bonus.lose!
    end

    def unsettled_bets_remaining
      unsettled_bets = customer_bonus.bets.where(settlement_status: nil)
      log_job_message(:info,
                      message: 'Checking customer bonus unsettled bets',
                      customer_bonus_id: customer_bonus.id,
                      bet_ids: unsettled_bets.pluck(:id))

      unsettled_bets.exists?
    end
  end
end
