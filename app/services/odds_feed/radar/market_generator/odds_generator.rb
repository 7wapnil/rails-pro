module OddsFeed
  module Radar
    module MarketGenerator
      class OddsGenerator < ::ApplicationService
        def initialize(market_data)
          @market_data = market_data
        end

        def call
          return if @market_data.outcome.nil?

          @market_data.outcome.each do |odd_data|
            generate_odd!(odd_data)
          rescue StandardError => e
            Rails.logger.error e.message
            next
          end
        end

        private

        def generate_odd!(odd_data)
          odd_id = "#{@market_data.external_id}:#{odd_data['id']}"
          Rails.logger.debug "Updating odd with external ID #{odd_id}"

          odd = prepare_odd(odd_id, odd_data)
          Rails.logger.debug "Updating odd ID #{odd_id}, #{odd_data}"

          begin
            odd.save!
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
            Rails.logger.warn ["Odd ID #{odd_id} creating failed", e]
            odd = prepare_odd(odd_id, odd_data)
            odd.save!
          end
        end

        def prepare_odd(external_id, payload)
          odd = Odd.find_or_initialize_by(external_id: external_id,
                                          market: @market_data.market_model)

          odd.assign_attributes(name: @market_data.odd_name(payload['id']),
                                status: payload['active'].to_i,
                                value: payload['odds'])
          odd
        end
      end
    end
  end
end
