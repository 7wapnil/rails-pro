# frozen_string_literal: true

module Audit
  class LogWriterWorker < ApplicationWorker
    sidekiq_options queue: 'audit_log_writer'

    def perform(payload)
      LogWriter.call(payload)
    end
  end
end
