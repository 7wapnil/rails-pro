# frozen_string_literal: true

module Mts
  module Publishers
    class BetCancellation < MessagePublisher
      EXCHANGE_NAME = 'arcanebet_arcanebet-Control'
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
    end
  end
end
