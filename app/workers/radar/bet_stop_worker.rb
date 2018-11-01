module Radar
  class BetStopWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::BetStopHandler
    end
  end
end
