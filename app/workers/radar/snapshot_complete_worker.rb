module Radar
  class SnapshotCompleteWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::SnapshotCompleteHandler
    end
  end
end
