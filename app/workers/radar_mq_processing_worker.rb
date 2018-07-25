class RadarMqProcessingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mq'

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
    event_processing_job_matchers = %w[<odds_change <fixtures_fixture]
    matcher = Regexp.new(event_processing_job_matchers.join('|'))
    scan_result = payload.scan matcher
    if event_processing_job_matchers.any? {|matcher| scan_result.include?(matcher)}
      parsed_payload = Nori.new.parse(payload)
      return EventProcessingWorker.perform_async(parsed_payload)
    end
    raise NotImplementedError
  end
end
