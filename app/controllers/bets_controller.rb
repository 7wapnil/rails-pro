class BetsController < ApplicationController
  def index
    if query_params && query_params[:created_at_lt].present?
      query_params[:created_at_lt] = query_params[:created_at_lt]
                                     .to_date
                                     .end_of_day
    end
    @dates = collect_query_dates
    @search = Bet.with_winnings.search(query_params)
    @bets = @search.result.order(id: :desc).page(params[:page])
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winnings
           .find(params[:id])
  end

  private

  def collect_query_dates
    {
      created_at_gteq:
        query_params ? query_params[:created_at_gteq] : nil,
      created_at_lt:
        query_params ? query_params[:created_at_lt] : nil
    }
  end
end
