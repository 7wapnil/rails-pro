# frozen_string_literal: true

module Scheduled
  class DailyReportWorker < ApplicationWorker
    def perform
      ::Reports::DailyReport.call
    end
  end
end
