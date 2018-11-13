require 'sidekiq-scheduler'

class PreMatchMarketsClosingWorker
  include Sidekiq::Worker

  def perform
    Markets::PreMatchMarketsClosingService.call
  end
end
