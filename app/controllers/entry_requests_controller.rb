# frozen_string_literal: true

class EntryRequestsController < ApplicationController
  def index
    @filter = EntryRequestsFilter.new(
      source: EntryRequest,
      query_params: query_params(:entry_requests),
      page: params[:page]
    )
  end

  def show
    @request = EntryRequest.find(params[:id])
  end
end
