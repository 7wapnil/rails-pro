module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options queue: 'odds_feed'

    def perform(payload)
      worker_class.new(XmlParser.parse(payload)).handle
    rescue StandardError => e
      Rails.logger.error e.message
    end

    def worker_class
      raise ::NotImplementedError
    end
  end
end
