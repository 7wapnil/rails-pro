module Radar
  class MessageProcessingWorker
    EVENT_PROCESSING_MATCHERS = %w[<odds_change].freeze
    ALIVE_MESSAGE_MATCHER = '<alive'.freeze

    include Sidekiq::Worker
    sidekiq_options queue: 'mq'

    def perform(payload)
      Rails.logger.debug "Received job: #{payload}"
      scan_result = scan_payload(payload)
      raise NotImplementedError unless match_result(payload, scan_result)
    end

    private

    def match_result(payload, scan_result)
      matched = false
      matched ||= detect_event_processing(payload, scan_result)
      matched ||= detect_alive_message(payload, scan_result)
      matched
    end

    def scan_payload(payload)
      matchers = EVENT_PROCESSING_MATCHERS + [ALIVE_MESSAGE_MATCHER]
      matcher_regexp = Regexp.new(matchers.join('|'))
      payload.scan matcher_regexp
    end

    def detect_alive_message(payload, scan_result)
      if scan_result.include?(ALIVE_MESSAGE_MATCHER)
        Radar::HeartbeatWorker.perform_async(Hash.from_xml(payload))
        return true
      end
      false
    end

    def detect_event_processing(payload, scan_result)
      matched = EVENT_PROCESSING_MATCHERS
                .any? { |matcher| scan_result.include?(matcher) }
      if matched
        parsed_payload = Nori.new.parse(payload)
        EventProcessingWorker.perform_async(parsed_payload)
        return true
      end
      false
    end
  end
end
