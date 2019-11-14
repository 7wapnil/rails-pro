# frozen_string_literal: true

module Reports
  class DailyReport < ApplicationService
    def call
      query = Reports::Queries::DailyStatsQuery.call

      DailyReportMailer.with(data: query).daily_report_mail.deliver_now
    end
  end
end
