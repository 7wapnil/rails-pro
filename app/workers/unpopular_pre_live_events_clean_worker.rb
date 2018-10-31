require 'sidekiq-scheduler'

class UnpopularPreLiveEventsCleanWorker
  include Sidekiq::Worker

  def perform
    Event
      .unpopular_pre_live
      .delete_all
  end
end
