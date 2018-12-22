module Radar
  class EventScopesLoadingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    lock: :until_executed,
                    on_conflict: :log

    def perform
      super()

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
