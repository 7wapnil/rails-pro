# frozen_string_literal: true

module Customers
  class EveryMatrixTransactionsController < ApplicationController
    find :customer, by: :customer_id

    def index
      @filter = EveryMatrix::TransactionsFilter.new(
        source: @customer.every_matrix_transactions,
        query_params: query_params(:transactions),
        page: params[:page]
      )
    end
  end
end
