class MarketsUpdateWorker
  include Sidekiq::Worker

  def perform
    # Rails.logger.debug "Received job: #{payload}"
  end
end
