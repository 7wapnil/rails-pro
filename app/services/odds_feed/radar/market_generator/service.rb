module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService
        def initialize(event_id, payload, timestamp)
          @market_data =
            MarketData.new(Event.find(event_id), payload, timestamp)
        end

        def call
          create_or_update_market!
          OddsGenerator.call(@market_data)
        end

        private

        # rubocop:disable Metrics/MethodLength
        def create_or_update_market!
          external_id = @market_data.external_id
          msg = <<-MESSAGE
            Updating market with ID #{external_id}, \
            event ID #{@market_data.event.id}, \
            #{market_attributes}
          MESSAGE
          Rails.logger.info msg.squish

          market.assign_attributes(market_attributes)

          begin
            market.save!
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
            Rails.logger.warn ["Market ID #{external_id} creating failed",
                               e.message]

            market.reload
            update_market_attributes!
          end
        end
        # rubocop:enable Metrics/MethodLength

        def market
          @market_data.market_model
        end

        def update_market_attributes!
          market.assign_attributes(market_attributes)
          market.save!
        end

        def market_attributes
          { name: @market_data.name, status: @market_data.status }
        end
      end
    end
  end
end
