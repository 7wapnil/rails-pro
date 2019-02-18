module Radar
  class BetCancelWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::BetCancelHandler
    end
  end
end
