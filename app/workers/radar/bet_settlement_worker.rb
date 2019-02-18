module Radar
  class BetSettlementWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    retry: 0

    def worker_class
      OddsFeed::Radar::BetSettlementHandler
    end
  end
end
