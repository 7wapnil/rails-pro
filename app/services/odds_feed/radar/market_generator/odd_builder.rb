module OddsFeed
  module Radar
    module MarketGenerator
      class OddBuilder < ::ApplicationService
        include JobLogger

        def initialize(market:, odd_data:, market_data:)
          @market = market
          @odd_data = odd_data
          @market_data = market_data
        end

        def call
          log_job_message(
            :debug,
            message: 'Building odd',
            event_id: external_id,
            odd_name: odd_name
          )
          build_odd
        end

        private

        attr_reader :market, :odd_data, :market_data

        def build_odd
          Odd.new(odd_attributes)
        end

        def odd_attributes
          attributes = { external_id: external_id,
                         market: market,
                         name: odd_name,
                         status: odd_status,
                         outcome_id: outcome_id }
          return attributes if odd_value.zero?

          attributes[:value] = odd_value
          attributes
        end

        def external_id
          @external_id ||= "#{market_data.external_id}:#{odd_data['id']}"
        end

        def odd_value
          @odd_value ||= odd_data['odds'].to_f
        end

        def odd_status
          @odd_status ||=
            odd_data['active'] == '1' ? Odd::ACTIVE : Odd::INACTIVE
        end

        def odd_name
          market_data.odd_name(odd_data['id'])
        end

        def outcome_id
          odd_data['id']
        end
      end
    end
  end
end
