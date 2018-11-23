module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload)
      worker_class.new(XmlParser.parse(payload)).handle
    rescue StandardError => e
      Rails.logger.error e.message
      raise e
    end

    def worker_class
      raise ::NotImplementedError
    end
  end
end
