# frozen_string_literal: true

module Scheduled
  class SalesReportsWorker < ApplicationWorker
    def perform
      ::Reports::SalesReports.call
    end
  end
end
