# frozen_string_literal: true

module Customers
  class EntriesController < ApplicationController
    find :customer, by: :customer_id

    def index
      @filter = Entries::Filter.new(
        source: @customer.entries,
        query_params: query_params(:entries),
        page: params[:page]
      )
    end
  end
end
