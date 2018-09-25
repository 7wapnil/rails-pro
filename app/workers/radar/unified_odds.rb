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
               prefetch: 10,
               threads: 10,
               timeout_job_after: 10

    MATCHERS = {
      event_processing: {
        matchers: %w[<odds_change].freeze,
        klass: OddsFeed::Radar::OddsChangeHandler
      },
      alive: {
        matchers: %w[<alive].freeze,
        klass: OddsFeed::Radar::AliveHandler
      },
      bet_settlement: {
        matchers: %w[<bet_settlement].freeze,
        klass: OddsFeed::Radar::BetSettlementHandler
      },
      bet_stop: {
        matchers: %w[<bet_stop].freeze,
        klass: OddsFeed::Radar::BetStopHandler
      },
      bet_cancel: {
        matchers: %w[<bet_cancel].freeze,
        klass: OddsFeed::Radar::BetCancelHandler
      },
      fixture_change: {
        matchers: %w[<fixture_change].freeze,
        klass: OddsFeed::Radar::FixtureChangeHandler
      }
    }.freeze

    def work(msg)
      initialized_handler = match_result(msg, scan_payload(msg))
      handle(initialized_handler)
    end

    def handle(handler)
      handler.handle
    rescue StandardError => e
      logger.error e
    end

    private

    def match_result(payload, scan_result)
      MATCHERS.each do |_, rule|
        rule_matchers = rule[:matchers]
        klass = rule[:klass]
        found = rule_matchers.any? { |matcher| scan_result.include?(matcher) }
        return klass.new(XmlParser.parse(payload)) if found
      end
      logger.warn 'No worker found for message'
      raise NotImplementedError
    end

    def scan_payload(payload)
      payload.scan Regexp.new(matchers.join('|'))
    end

    def matchers
      MATCHERS.flat_map { |_, rule| rule[:matchers] }
    end
  end
end
