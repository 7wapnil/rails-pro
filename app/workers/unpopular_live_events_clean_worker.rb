require 'sidekiq-scheduler'

class UnpopularLiveEventsCleanWorker
  include Sidekiq::Worker

  def perform
    Event
      .unpopular_live
      .delete_all
  end
end
