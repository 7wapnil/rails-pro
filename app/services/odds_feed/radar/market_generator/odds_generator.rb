module OddsFeed
  module Radar
    module MarketGenerator
      class OddsGenerator < ::ApplicationService
        def initialize(market, market_data)
          @market = market
          @market_data = market_data
          @odds = []
        end

        def call
          build
          @odds
        end

        private

        def build
          return if @market_data.outcome.blank?

          @market_data.outcome.each do |odd_data|
            odd = build_odd(odd_data)
            @odds << odd if odd && valid?(odd)
          rescue StandardError => e
            Rails.logger.error ({ exception: e, paylaod: odd_data }.to_json)
            next
          end
        end

        def valid?(odd)
          return true if odd.valid?

          msg = <<-MESSAGE
            Odd '#{odd.external_id}' is invalid: \
            #{odd.errors.full_messages.join("\n")}
          MESSAGE
          Rails.logger.warn msg.squish
          false
        end

        def build_odd(odd_data)
          return odd_data_is_not_payload(odd_data) unless odd_data.is_a?(Hash)

          external_id = "#{@market_data.external_id}:#{odd_data['id']}"
          Rails.logger.debug "Building odd ID #{external_id}, #{odd_data}"

          Odd.new(external_id: external_id,
                  market: @market,
                  name: @market_data.odd_name(odd_data['id']),
                  status: odd_data['active'].to_i,
                  value: odd_data['odds'])
        end

        def odd_data_is_not_payload(odd_data)
          Rails.logger.warn(
            "Odd data should be a payload, but received: `#{odd_data}`"
          )
        end
      end
    end
  end
end
