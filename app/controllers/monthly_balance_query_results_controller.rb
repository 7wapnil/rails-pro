# frozen_string_literal: true

class MonthlyBalanceQueryResultsController < ApplicationController
  def index
    @filter = MonthlyBalanceQueryResultsFilter.new(page: params[:page])
  end
end
