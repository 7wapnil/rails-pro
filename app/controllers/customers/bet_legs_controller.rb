# frozen_string_literal: true

module Customers
  class BetLegsController < ApplicationController
    find :customer, by: :customer_id
    find :bet_leg, by: %i[bet_legs bet_leg]

    def update
      @bet_leg.update!(bet_leg_params)

      redirect_to bet_path(@bet_leg.bet),
                  flash: { success: t('messages.bet_legs.flash') }
    rescue StandardError => error
      redirect_back fallback_location: root_path,
                    flash: { error: error.message }
    end

    private

    def bet_leg_params
      params
        .require(:bet_legs)
        .permit(:settlement_status)
        .merge(
          settlement_initiator: current_user
        )
    end
  end
end
