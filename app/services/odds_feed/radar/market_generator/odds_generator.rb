module OddsFeed
  module Radar
    module MarketGenerator
      class OddsGenerator < ::ApplicationService
        def initialize(market_data)
          @market_data = market_data
          @odds = []
        end

        def call
          return if @market_data.outcome.blank?

          generate_odds
        end

        private

        def build_odds
          @market_data.outcome.each do |odd_data|
            @odds << build_odd(odd_data)
          end
        end

        def generate_odds
          build_odds
          Odd.import([:name, :status, :value, :market_id, :external_id],
                     @odds,
                     on_duplicate_key_update: { conflict_target: [:external_id],
                                                columns: [:status, :value] })
        end

        def build_odd(odd_data)
          return odd_data_is_not_payload(odd_data) unless odd_data.is_a?(Hash)

          odd_id = "#{@market_data.external_id}:#{odd_data['id']}"
          Rails.logger.debug "Updating odd with external ID #{odd_id}"

          odd = prepare_odd(odd_id, odd_data)
          Rails.logger.debug "Updating odd ID #{odd_id}, #{odd_data}"

          odd
        end

        def odd_data_is_not_payload(odd_data)
          Rails.logger.warn(
            "Odd data should be a payload, but received: `#{odd_data}`"
          )
        end

        def prepare_odd(external_id, payload)
          Odd.new(external_id: external_id,
                  market: @market_data.market_model,
                  name: @market_data.odd_name(payload['id']),
                  status: payload['active'].to_i,
                  value: payload['odds'])
        end
      end
    end
  end
end
