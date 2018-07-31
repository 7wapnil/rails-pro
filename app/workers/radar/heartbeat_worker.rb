module Radar
  class HeartbeatWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'critical'

    def perform(payload)
      OddsFeed::Radar::AliveHandler.new(payload).handle
    end
  end
end
