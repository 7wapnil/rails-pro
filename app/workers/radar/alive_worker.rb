module Radar
  class AliveWorker < BaseUofWorker
    def worker_class
      OddsFeed::Radar::AliveHandler
    end
  end
end
