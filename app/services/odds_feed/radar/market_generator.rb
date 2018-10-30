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
        # rubocop:disable Metrics/LineLength
        msg = "Updating market with external ID #{external_id}, #{market_attributes}"
        # rubocop:enable Metrics/LineLength
        Rails.logger.debug msg

        market.assign_attributes(market_attributes)

        begin
          market.save!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.warn ["Market ID #{external_id} creating failed", e]

          @market = nil
          update_market_attributes!
        end
        market
      end

      def update_market_attributes!
        market.assign_attributes(market_attributes)
        market.save!
      end

      def market_attributes
        { name: transpiler.market_name, status: market_status }
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
        Rails.logger.debug "Updating odd with external ID #{odd_id}"

        return unless odd_valid?(odd_id, odd_data)

        odd = prepare_odd(odd_id, odd_data)

        attributes = odd.attributes.slice(:name, :status, :value)
        Rails.logger.debug "Updating odd external ID #{odd_id}, #{attributes}"

        begin
          odd.save!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.warn ["Odd ID #{odd_id} creating failed", e]
          odd = prepare_odd(odd_id, odd_data)
          odd.save!
        end
      end

      def prepare_odd(external_id, payload)
        odd = Odd.find_or_initialize_by(external_id: external_id,
                                        market: market)
        attributes = { name: transpiler.odd_name(payload['id']),
                       status: payload['active'].to_i,
                       value: payload['odds'] }

        odd.assign_attributes(attributes)

        odd
      end

      def odd_valid?(odd_id, odd_data)
        return true unless odd_data['odds'].blank?

        Rails.logger.warn "Odd ID '#{odd_id}' is invalid, data: #{odd_data}"
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
