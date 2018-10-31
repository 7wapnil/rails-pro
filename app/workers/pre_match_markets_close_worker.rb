require 'sidekiq-scheduler'

class PreMatchMarketsCloseWorker
  include Sidekiq::Worker

  def perform
    Markets::PreMatchMarketsCloseService.call
  end
end
