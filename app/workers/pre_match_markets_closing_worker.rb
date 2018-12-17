require 'sidekiq-scheduler'

class PreMatchMarketsClosingWorker < ApplicationWorker
  def perform
    super()

    Markets::PreMatchMarketsClosingService.call
  end
end
