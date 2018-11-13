module Radar
  class BetCancelWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::BetCancelHandler
    end
  end
end
