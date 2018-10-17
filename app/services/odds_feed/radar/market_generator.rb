module OddsFeed
  module Radar
    class MarketGenerator
      def initialize(event, market_data)
        @event = event
        @market_data = market_data
      end

      def generate
        create_or_update_market!
        generate_odds!
      end

      private

      def market
        @market ||= Market.find_or_initialize_by(
          external_id: external_id,
          event: @event
        )
      end

      def create_or_update_market!
        attributes = { name: transpiler.market_name,
                       status: market_status }
        msg = "Updating market with external ID #{external_id}, #{attributes}"
        Rails.logger.info msg
        market.assign_attributes(attributes)
        market.save!
        market
      end

      # TODO: use external id generator
      def external_id
        id = "#{@event.external_id}:#{@market_data['id']}"
        specs = specifiers
        return id if specs.empty?

        "#{id}/#{specs}"
      end

      def specifiers
        @market_data['specifiers'] || ''
      end

      def market_status
        status_map[@market_data['status']] || Market::DEFAULT_STATUS
      end

      def status_map
        {
          '-2': :handed_over,
          '-1': :suspended,
          '0': :inactive,
          '1': :active
        }.stringify_keys
      end

      def generate_odds!
        return if @market_data['outcome'].nil?

        @market_data['outcome'].each do |odd_data|
          generate_odd!(odd_data)
        rescue StandardError => e
          Rails.logger.error e
          next
        end
      end

      def generate_odd!(odd_data)
        odd_id = "#{market.external_id}:#{odd_data['id']}"
        Rails.logger.info "Updating odd with external ID #{odd_id}"
        return unless odd_valid?(odd_id, odd_data)

        odd = Odd.find_or_initialize_by(external_id: odd_id,
                                        market: market)
        attributes = { name: transpiler.odd_name(odd_data['id']),
                       status: odd_data['active'].to_i,
                       value: odd_data['odds'] }

        Rails.logger.info "Updating odd external ID #{odd_id}, #{attributes}"

        odd.assign_attributes(attributes)
        odd.save!
      end

      def odd_valid?(odd_id, odd_data)
        return true unless odd_data['odds'].blank?

        Rails.logger.info "Odd value for odd #{odd_id} is empty"
        false
      end

      def transpiler
        @transpiler ||= Transpiler.new(@event,
                                       @market_data['id'],
                                       @market_data['specifiers'] || '')
      end
    end
  end
end
