require 'sidekiq-scheduler'

class UnpopularLiveEventsCleanUpWorker
  include Sidekiq::Worker

  def perform
    Event.unpopular_live.delete_all
  end
end
