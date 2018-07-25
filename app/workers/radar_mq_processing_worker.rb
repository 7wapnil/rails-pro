class RadarMqProcessingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mq'

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
    event_processing_job_matchers = %w[<odds_change <fixtures_fixture]
    matcher = Regexp.new(event_processing_job_matchers.join('|'))
    scan_result = payload.scan matcher
    if event_processing_job_matchers.any? {|matcher| scan_result.include?(matcher)}
      return EventProcessingWorker.perform_async(payload)
    end
    raise NotImplementedError
  end
end
