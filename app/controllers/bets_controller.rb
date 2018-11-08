class BetsController < ApplicationController
  include DateIntervalFilters

  def index
    @search = Bet.includes(:market)
                 .with_winnings
                 .with_sport
                 .with_tournament
                 .with_country
                 .search(prepare_interval_filter(query_params, :created_at))

    @bets = @search.result.order(id: :desc).page(params[:page])
    @sports = Title.pluck(:name)
    @tournaments = EventScope.tournament.pluck(:name)
    @countries = EventScope.country.pluck(:name)
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winnings
           .find(params[:id])
  end
end
