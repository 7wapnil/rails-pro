# frozen_string_literal: true

class BetsController < ApplicationController
  decorates_assigned :bet

  def index
    @filter = BetsFilter.new(source: Bet,
                             query_params: query_params(:bets),
                             page: params[:page])
  end

  def show
    @bet = Bet.includes(:currency, :customer, bet_legs: :odd)
              .with_winning_amount
              .find(params[:id])
  end
end
