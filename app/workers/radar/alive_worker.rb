module Radar
  class AliveWorker < BaseUofWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def worker_class
      OddsFeed::Radar::Alive::Handler
    end
  end
end
