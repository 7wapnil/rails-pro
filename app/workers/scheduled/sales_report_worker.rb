# frozen_string_literal: true

module Scheduled
  class SalesReportWorker < ApplicationWorker
    def perform
      ::Reports::SalesReport.call
    end
  end
end
