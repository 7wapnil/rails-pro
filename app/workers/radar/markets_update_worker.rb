module Radar
  class MarketsUpdateWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    unique_across_queues: true

    def perform
      log_job_message(:debug, 'Updating BetRadar market templates')
      markets_data.each do |market_data|
        OddsFeed::Radar::MarketTemplates::CreateOrUpdate.call(
          market_data: market_data,
          variant_outcomes_map: variant_outcomes_map
        )
      rescue StandardError => error
        log_job_failure(error)
        Airbrake.notify(error)
        next
      end
    end

    private

    def markets_data
      Array.wrap(
        client
          .markets(include_mappings: true)
          .dig('market_descriptions', 'market')
      )
    end

    def variant_outcomes_map
      @variant_outcomes_map ||=
        Array
        .wrap(variants_payload)
        .map { |variant| map_variant_outcomes_row(variant) }
        .to_h
    end

    def variants_payload
      client
        .all_market_variants
        .dig('variant_descriptions', 'variant')
    end

    def map_variant_outcomes_row(variant)
      outcomes = Array.wrap(variant.dig('outcomes', 'outcome'))

      [
        variant['id'],
        { 'outcomes' => { 'outcome' => outcomes } }
      ]
    end

    def client
      @client ||= OddsFeed::Radar::Client.new
    end
  end
end
