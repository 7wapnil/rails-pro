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

        send_message!

        update_bet
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
        create_exchange(::Mts::Session.instance.opened_connection)
          .publish(
            formatted_message,
            message_params
          )
      end

      def create_exchange(conn)
        channel = conn.create_channel
        exchange = channel.exchange(self.class::EXCHANGE_NAME,
                                    type: self.class::EXCHANGE_TYPE,
                                    durable: true)
        channel.queue(self.class::QUEUE_NAME, durable: true)
               .bind(self.class::EXCHANGE_NAME)
        exchange
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
