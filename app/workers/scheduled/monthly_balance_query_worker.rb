# frozen_string_literal: true

module Scheduled
  class MonthlyBalanceQueryWorker < ApplicationWorker
    def perform
      ::Reports::Queries::MonthlyBalanceQuery.call
    end
  end
end
