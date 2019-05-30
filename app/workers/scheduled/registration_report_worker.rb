# frozen_string_literal: true

module Scheduled
  class RegistrationReportWorker < ApplicationWorker
    def perform
      Reports::RegistrationReport.call
    end
  end
end
