require 'sidekiq-scheduler'

class PreMatchMarketsClosingWorker < ApplicationWorker
  def perform
    Markets::PreMatchMarketsClosingService.call
  end
end
