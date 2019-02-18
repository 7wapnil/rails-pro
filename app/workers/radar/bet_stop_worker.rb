module Radar
  class BetStopWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::BetStopHandler
    end
  end
end
