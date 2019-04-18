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

        raise 'No MTS connection.' unless send_message!

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

      private

      def send_message!
        ::Mts::SingleSession.instance.session.within_connection do |conn|
          break unless conn

          create_exchange(conn)
            .publish(
              formatted_message,
              content_type: 'application/json',
              routing_key: 'cancel',
              persistent: false,
              headers: { 'replyRoutingKey': self.class::ROUTING_KEY }
            )
        end
      end

      def create_exchange(conn)
        conn
          .create_channel
          .exchange(self.class::EXCHANGE_NAME,
                    type: self.class::EXCHANGE_TYPE,
                    durable: true)
      end
    end
  end
end
