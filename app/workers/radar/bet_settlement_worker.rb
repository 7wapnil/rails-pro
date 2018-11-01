module Radar
  class BetSettlementWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::BetSettlementHandler
    end
  end
end
