# frozen_string_literal: true

module Mts
  module Publishers
    class MessagePublisher
      include JobLogger

      def initialize(bet:)
        @bet = bet
      end

      def self.publish!(bet:)
        new(bet: bet).publish!
      end

      def publish!
        log_message

        update_bet

        send_message!
      end

      protected

      attr_reader :bet

      def log_message
        error_msg = "#{__method__} needs to be implemented in #{self.class}"
        raise NotImplementedError, error_msg
      end

      def message
        error_msg = "#{__method__} needs to be implemented in #{self.class}"
        raise NotImplementedError, error_msg
      end

      def update_bet
        error_msg = "#{__method__} needs to be implemented in #{self.class}"
        raise NotImplementedError, error_msg
      end

      def additional_params
        {}
      end

      private

      def send_message!
        create_exchange(::Mts::Session.instance.opened_connection) do |exchange|
          exchange.publish(
            formatted_message,
            message_params
          )
        end
      end

      def create_exchange(conn) # # rubocop:disable Metrics/MethodLength
        begin
          channel = conn.create_channel
          channel.queue(self.class::QUEUE_NAME, durable: true)
                 .bind(self.class::CONSUMER_EXCHANGE_NAME,
                       routing_key: self.class::ROUTING_KEY)
          exchange = channel.exchange(self.class::EXCHANGE_NAME,
                                      type: self.class::EXCHANGE_TYPE,
                                      durable: true)
          yield exchange
        rescue StandardError => e
          bet.register_failure(e)
          WebSocket::Client.instance.trigger_bet_update(bet)
          log_job_message(:error, message: e.message, error_object: e)
        end
      ensure
        channel&.close
      end

      def message_params
        {
          content_type: 'application/json',
          persistent: false,
          headers: { 'replyRoutingKey': self.class::ROUTING_KEY }
        }.merge(additional_params)
      end
    end
  end
end
