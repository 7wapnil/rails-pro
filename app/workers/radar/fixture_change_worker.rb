module Radar
  class FixtureChangeWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::FixtureChangeHandler
    end
  end
end
