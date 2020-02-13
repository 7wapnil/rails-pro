# frozen_string_literal: true

module Audit
  class LogWriter < ApplicationService
    def initialize(payload)
      @payload = payload
    end

    def call
      AuditLog.create!(payload)
    end

    private

    attr_reader :payload
  end
end
