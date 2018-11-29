module Radar
  class OddsChangeWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end
  end
end
