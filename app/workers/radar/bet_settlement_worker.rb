module Radar
  class BetSettlementWorker < BaseUofWorker
    sidekiq_options queue: :uof_priority, retry: 0

    def worker_class
      OddsFeed::Radar::BetSettlementHandler
    end
  end
end
