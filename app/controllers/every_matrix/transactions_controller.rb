# frozen_string_literal: true

module EveryMatrix
  class TransactionsController < ApplicationController
    find :transaction, only: %i[show], class: EveryMatrix::Transaction
    decorates_assigned :transaction

    def index
      @filter = EveryMatrix::TransactionsFilter.new(
        source: EveryMatrix::Transaction,
        query_params: query_params(:transactions),
        page: params[:page]
      )
    end
  end
end
