module OddsFeed
  module Radar
    module MarketGenerator
      class OddsGenerator < ::ApplicationService
        include JobLogger

        def initialize(market, market_data)
          @market = market
          @market_data = market_data
          @odds = []
        end

        def call
          build
          odds
        end

        private

        attr_reader :market, :market_data, :odds

        def build
          return if market_data.outcome.blank?

          market_data.outcome.each { |odd_data| build_and_push_odd(odd_data) }
        end

        def build_and_push_odd(odd_data)
          return odd_data_is_not_payload(odd_data) unless odd_data.is_a?(Hash)

          odd = build_odd(odd_data)
          @odds << odd if odd_valid?(odd)
        rescue StandardError => e
          log_job_failure(e)
        end

        def odd_data_is_not_payload(odd_data)
          log_job_message(
            :warn, "Odd data should be a payload, but received: `#{odd_data}`"
          )
        end

        def build_odd(odd_data)
          OddBuilder.call(
            market: market,
            odd_data: odd_data,
            market_data: market_data
          )
        end

        def odd_valid?(odd)
          return true if odd.valid?

          msg = <<-MESSAGE
            Odd '#{odd.external_id}' is invalid: \
            #{odd.errors.full_messages.join("\n")}
          MESSAGE
          log_job_message(:warn, msg.squish)
          false
        end
      end
    end
  end
end
