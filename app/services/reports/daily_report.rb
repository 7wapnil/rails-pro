module Reports
  class DailyReport < ApplicationService
    def call
      query = Reports::Queries::DailyStatsQuery.new.call

      DailyReportMailer.with(data: query).email.deliver_now
    end
  end
end
