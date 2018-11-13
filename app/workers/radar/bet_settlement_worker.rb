module Radar
  class BetSettlementWorker < BaseUofWorker
    sidekiq_options retry: 0

    def worker_class
      OddsFeed::Radar::BetSettlementHandler
    end
  end
end
