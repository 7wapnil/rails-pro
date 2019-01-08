module Radar
  class UnifiedOdds
    include Sneakers::Worker

    def self.routing_key(node_id: nil, listen_all: nil)
      listen_all = ENV['RADAR_MQ_LISTEN_ALL'] != 'false' if listen_all.nil?
      listen_all_key = '*.*.*.*.*.*.*.-.#'

      node_id ||= ENV['RADAR_MQ_NODE_ID'] || Time.now.strftime('1%H%M%S%L')
      listen_node_key = "*.*.*.*.*.*.*.#{node_id}.#"

      [].tap do |routing_key|
        routing_key << listen_node_key
        routing_key << listen_all_key if listen_all
      end
    end

    from_queue '',
               env: nil,
               exchange: ENV['RADAR_MQ_EXCHANGE'],
               exchange_options: { passive: true },
               routing_key: routing_key,
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
      },
      snapshot_complete: {
        matchers: %w[<snapshot_complete].freeze,
        klass: SnapshotCompleteWorker
      }
    }.freeze

    def work(msg)
      match_result(scan_payload(msg))
        .perform_async(msg, Time.now.to_f)
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
