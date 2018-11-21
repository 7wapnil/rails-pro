module Radar
  class BetStopWorker < BaseUofWorker
    sidekiq_options queue: :uof_priority

    def worker_class
      OddsFeed::Radar::BetStopHandler
    end
  end
end
