require 'sidekiq-scheduler'

module Radar
  class EventScopesLoadingWorker
    include Sidekiq::Worker

    def perform
      tournaments_response.each do |tournament|
        EventScopesCreatingWorker.perform_async(tournament)
      end
    end

    def api_client
      @api_client = OddsFeed::Radar::Client.new
    end

    def tournaments_response
      api_client.tournaments['tournaments']['tournament']
    end
  end
end
