# frozen_string_literal: true

class TransactionsController < ApplicationController
  def index
    @filter = CustomerTransactionsFilter.new(
      source: CustomerTransaction,
      query_params: query_params(:customer_transactions),
      page: params[:page],
      per_page: 20
    )
  end
end
