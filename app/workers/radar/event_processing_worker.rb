module Radar
  class EventProcessingWorker
    include Sidekiq::Worker

    def perform(payload)
      ActiveRecord::Base.transaction do
        OddsFeed::Radar::OddsChangeHandler.new(payload).handle
      end
    rescue StandardError => e
      Rails.logger.error e
      Rails.logger.debug e.backtrace
    end
  end
end
