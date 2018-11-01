module Radar
  class UnifiedOdds
    include Sneakers::Worker
    from_queue '',
               env: nil,
               exchange: ENV['RADAR_MQ_EXCHANGE'],
               exchange_options: { passive: true },
               routing_key: '#',
               durable: false,
               ack: false

    MATCHERS = {
      event_processing: {
        matchers: %w[<odds_change].freeze,
        klass: OddsChangeWorker
      },
      alive: {
        matchers: %w[<alive].freeze,
        klass: AliveWorker
      },
      bet_settlement: {
        matchers: %w[<bet_settlement].freeze,
        klass: BetSettlementWorker
      },
      bet_stop: {
        matchers: %w[<bet_stop].freeze,
        klass: BetStopWorker
      },
      bet_cancel: {
        matchers: %w[<bet_cancel].freeze,
        klass: BetCancelWorker
      },
      fixture_change: {
        matchers: %w[<fixture_change].freeze,
        klass: FixtureChangeWorker
      }
    }.freeze

    def work(msg)
      match_result(scan_payload(msg)).perform_async(msg)
    end

    private

    def match_result(scan_result)
      MATCHERS.each do |_, rule|
        rule_matchers = rule[:matchers]
        klass = rule[:klass]
        found = rule_matchers.any? { |matcher| scan_result.include?(matcher) }
        return klass if found
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
