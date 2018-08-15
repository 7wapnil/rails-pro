module OddsFeed
  module Radar
    class MarketGenerator
      def initialize(event, market_data)
        @event = event
        @market_data = market_data
      end

      def generate
        market = create_or_update_market!
        generate_odds!(market)
      end

      private

      def create_or_update_market!
        external_id = "#{@event.external_id}:#{@market_data['id']}"
        market = Market.find_or_initialize_by(external_id: external_id,
                                              event: @event)
        market.assign_attributes(name: transpiler.market_name,
                                 priority: 0,
                                 status: market_status)
        market.save!
        emit_market_update(market)
        market
      end

      def emit_market_update(market)
        return unless market.saved_changes.keys.any? do |i|
          %w[name priority status].include? i
        end

        WebSocket::Client.instance.emit(WebSocket::Signals::UPDATE_MARKET,
                                        id: market.id.to_s,
                                        eventId: market.event.id.to_s,
                                        name: market.name,
                                        priority: market.priority,
                                        status: market.status)
      end

      def market_status
        status_map[@market_data['status']] || Market::DEFAULT_STATUS
      end

      def status_map
        {
          '-1': Market::STATUSES[:suspended],
          '0': Market::STATUSES[:inactive],
          '1': Market::STATUSES[:active]
        }.stringify_keys
      end

      def generate_odds!(market)
        return if @market_data['outcome'].nil?
        @market_data['outcome'].each do |odd_data|
          generate_odd!(market, odd_data)
        end
      end

      def generate_odd!(market, odd_data)
        odd_id = "#{market.external_id}:#{odd_data['id']}"
        odd = Odd.find_or_initialize_by(external_id: odd_id,
                                        market: market)
        odd.assign_attributes(name: transpiler.odd_name(odd_data['id']),
                              status: odd_data['active'].to_i,
                              value: odd_data['odds'])
        odd.save!
        emit_odd_update(odd)
      end

      def emit_odd_update(odd)
        WebSocket::Client.instance.emit(WebSocket::Signals::ODD_CHANGE,
                                        id: odd.id.to_s,
                                        marketId: odd.market.id.to_s,
                                        eventId: odd.market.event.id.to_s,
                                        name: odd.name,
                                        value: odd.value,
                                        status: odd.status)
      end

      def transpiler
        @transpiler ||= Transpiler.new(@event,
                                       @market_data['id'],
                                       @market_data['specifiers'])
      end
    end
  end
end
