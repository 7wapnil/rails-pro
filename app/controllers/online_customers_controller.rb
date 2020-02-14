# frozen_string_literal: true

class OnlineCustomersController < ApplicationController
  def index
    @filter = OnlineCustomersFilter.new(source: Customer,
                                        query_params: query_params(:customers),
                                        page: params[:page])
  end
end
