class RadarMqProcessingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mq'

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
  end
end
