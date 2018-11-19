module BetPlacement
  class BettingLimitsValidationService < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def call
      customer = @bet.customer
      global_limit = BettingLimit
                     .find_by(
                       customer: customer,
                       title: nil
                     )
      limit_by_title = BettingLimit
                       .find_by(
                         customer: customer,
                         title: @bet.odd.market.event.title
                       )
      validate!(global_limit, @bet) && validate!(limit_by_title, @bet)
    end

    private

    def validate!(limit, bet)
      limit&.validate!(bet)
    end
  end
end
