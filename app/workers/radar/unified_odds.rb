module Radar
  class UnifiedOdds
    include Sneakers::Worker
    from_queue '',
               env: nil,
               exchange: ENV['RADAR_MQ_EXCHANGE'],
               exchange_options: { passive: true },
               routing_key: '#',
               durable: false,
               ack: false,
               prefetch: 1,
               threads: 1

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

    def work(_msg)
      logger.info 'Message processing worker received a new job'
      raise NotImplementedError
      # scan_result = scan_payload(msg)
      # raise NotImplementedError unless match_result(msg, scan_result)
    end

    private

    def match_result(payload, scan_result)
      MATCHERS.each do |_, rule|
        rule_matchers = rule[:matchers]
        klass = rule[:klass]
        found = rule_matchers.any? { |matcher| scan_result.include?(matcher) }
        return klass.perform_async(XmlParser.parse(payload)) if found
      end
      logger.debug 'No worker found for message'
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
