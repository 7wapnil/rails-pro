module Radar
  class OddsChangeWorker < BaseUofWorker
    sidekiq_options queue: :uof_priority

    def worker_class
      OddsFeed::Radar::OddsChangeHandler
    end
  end
end
