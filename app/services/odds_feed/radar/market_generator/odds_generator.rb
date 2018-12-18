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
          @odds
        end

        private

        def build
          return if @market_data.outcome.blank?

          valuable_outcome.each do |odd_data|
            odd = build_odd(odd_data)
            @odds << odd if odd && valid?(odd)
          rescue StandardError => e
            log_job_failure(e)
            next
          end
        end

        def valuable_outcome
          @market_data.outcome.reject { |odd_data| odd_data['odds'].to_f.zero? }
        end

        def valid?(odd)
          return true if odd.valid?

          msg = <<-MESSAGE
            Odd '#{odd.external_id}' is invalid: \
            #{odd.errors.full_messages.join("\n")}
          MESSAGE
          log_job_message(:warn, msg.squish)
          false
        end

        def build_odd(odd_data)
          unless odd_data.is_a?(Hash)
            odd_data_is_not_payload(odd_data)
            return
          end

          external_id = "#{@market_data.external_id}:#{odd_data['id']}"
          log_job_message(
            :debug, "Building odd ID #{external_id}, #{odd_data}"
          )

          Odd.new(external_id: external_id,
                  market: @market,
                  name: @market_data.odd_name(odd_data['id']),
                  status: odd_data['active'].to_i,
                  value: odd_data['odds'])
        end

        def odd_data_is_not_payload(odd_data)
          log_job_message(
            :warn, "Odd data should be a payload, but received: `#{odd_data}`"
          )
        end
      end
    end
  end
end
