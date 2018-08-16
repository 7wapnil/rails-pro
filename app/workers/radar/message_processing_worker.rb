module Radar
  class MessageProcessingWorker
    MATCHERS = {
      event_processing: {
        matchers: %w[<odds_change].freeze,
        klass: Radar::EventProcessingWorker
      },
      alive: {
        matchers: %w[<alive].freeze,
        klass: Radar::HeartbeatWorker
      }
    }.freeze

    include Sidekiq::Worker
    sidekiq_options queue: 'mq', retries: false

    def perform(payload)
      Rails.logger.debug 'Message processing worker received a new job'
      scan_result = scan_payload(payload)
      raise NotImplementedError unless match_result(payload, scan_result)
    end

    private

    def match_result(payload, scan_result)
      MATCHERS.each do |_, rule|
        rule_matchers = rule[:matchers]
        klass = rule[:klass]
        found = rule_matchers.any? { |matcher| scan_result.include?(matcher) }
        return klass.perform_async(XmlParser.parse(payload)) if found
      end
      Rails.logger.debug 'No worker found for message'
      false
    end

    def scan_payload(payload)
      payload.scan Regexp.new(matchers.join('|'))
    end

    def matchers
      MATCHERS.flat_map { |_, rule| rule[:matchers] }
    end
  end
end
