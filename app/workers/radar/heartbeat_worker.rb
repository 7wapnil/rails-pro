module Radar
  class HeartbeatWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'critical'

    def perform
      raise NotImplementedError
    end
  end
end
