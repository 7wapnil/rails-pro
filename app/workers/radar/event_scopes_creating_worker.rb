module Radar
  class EventScopesCreatingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(payload)
      OddsFeed::Radar::EventScopesService.call(payload)
    end
  end
end
