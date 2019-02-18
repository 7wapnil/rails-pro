module Radar
  class FixtureChangeWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::FixtureChangeHandler
    end
  end
end
