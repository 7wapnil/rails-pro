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
          log_job_message(:debug, "Build odd ID #{external_id}, #{odd_data}")

          return found_odd_with_updated_status if odd_value.zero? && found_odd

          build_odd
        end

        private

        attr_reader :market, :odd_data, :market_data

        def external_id
          @external_id ||= "#{market_data.external_id}:#{odd_data['id']}"
        end

        def odd_value
          @odd_value ||= odd_data['odds'].to_f
        end

        def found_odd
          @found_odd ||= Odd.find_by(external_id: external_id)
        end

        def found_odd_with_updated_status
          found_odd.assign_attributes(status: odd_status)
          found_odd
        end

        def odd_status
          @odd_status ||=
            odd_data['active'] == '1' ? Odd::ACTIVE : Odd::INACTIVE
        end

        def build_odd
          Odd.new(
            external_id: external_id,
            market: market,
            name: odd_name,
            status: odd_status,
            value: odd_value
          )
        end

        def odd_name
          market_data.odd_name(odd_data['id'])
        end
      end
    end
  end
end
