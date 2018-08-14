module Radar
  class EventProcessingWorker
    include Sidekiq::Worker

    def perform(payload)
      Rails.logger.debug "Received job: #{payload}"
      ActiveRecord::Base.transaction do
        OddsFeed::Radar::OddsChangeHandler.new(payload)
      end
    rescue StandardError => e
      Rails.logger.error e
    end
  end
end
