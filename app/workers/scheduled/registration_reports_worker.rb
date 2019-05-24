# frozen_string_literal: true

module Scheduled
  class RegistrationReportsWorker < ApplicationWorker
    def perform
      Reports::RegistrationReports.call
    end
  end
end
