module Radar
  class OddsChangeWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end
  end
end
