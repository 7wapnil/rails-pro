# frozen_string_literal: true

module Mts
  module Publishers
    class BetCancellation < MessagePublisher
      CONSUMER_EXCHANGE_NAME = 'arcanebet_arcanebet-Reply'
      EXCHANGE_NAME = 'arcanebet_arcanebet-Control'
      QUEUE_NAME = ENV['MTS_MQ_QUEUE_REPLY']
      ROUTING_KEY = ENV['MTS_MQ_TICKET_CANCELLATION_RK']
      MESSAGE_VERSION = '2.3'
      CANCEL_ROUTING_KEY = 'cancel'
      TIMEOUT_CODE = 102
      EXCHANGE_TYPE = :topic

      protected

      def log_message
        log_job_message(:info, message: 'MTS Cancellation requested',
                               bet_id: bet.id)
      end

      def message
        @message ||= {
          'timestampUtc': timestamp,
          'ticketId': bet.validation_ticket_id,
          sender: { 'bookmakerId': ENV['MTS_BOOKMAKER_ID'] },
          code: TIMEOUT_CODE,
          version: MESSAGE_VERSION
        }
      end

      def formatted_message
        message.to_json
      end

      def update_bet
        bet.timed_out_external_validation!
        emit_websocket
      end

      def additional_params
        {
          routing_key: CANCEL_ROUTING_KEY
        }
      end

      private

      def timestamp
        (Time.now.to_f * 1000).to_i
      end

      def emit_websocket
        WebSocket::Client.instance.trigger_bet_update(bet)
      end
    end
  end
end
