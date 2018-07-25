class RadarMqProcessingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mq'

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
    event_message_matchers = %w[<odds_change]
    matcher_regexp = Regexp.new(event_message_matchers.join('|'))
    scan_result = payload.scan matcher_regexp
    if event_message_matchers.any? { |matcher| scan_result.include?(matcher) }
      parsed_payload = Nori.new.parse(payload)
      return EventProcessingWorker.perform_async(parsed_payload)
    end
    raise NotImplementedError
  end
end
