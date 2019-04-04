# frozen_string_literal: true

module OddsFeed
  module Radar
    class BetStopHandler < RadarMessageHandler
      def handle
        emit_event_bet_stopped
        update_markets
      end

      private

      def emit_event_bet_stopped
        WebSocket::Client
          .instance
          .trigger_event_bet_stop(event, market_status)
      end

      def event
        @event ||= Event.find_by!(external_id: event_id)
      rescue ActiveRecord::RecordNotFound
        raise I18n.t('errors.messages.nonexistent_event', id: event_id)
      end

      def event_id
        input_data['event_id']
      end

      def input_data
        payload['bet_stop']
      end

      def market_status
        @market_status ||= MarketStatus.stop_status(market_status_code)
      end

      def market_status_code
        input_data['market_status']
      end

      def update_markets
        markets_to_be_changed_query.update_all(status: market_status)
      end

      def markets_to_be_changed_query
        Market
          .joins(:event)
          .where(
            status: Market::ACTIVE,
            events: { external_id: event_id }
          )
      end
    end
  end
end
