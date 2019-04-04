# frozen_string_literal: true

module Mts
  module Publishers
    class BetValidation < MessagePublisher
      EXCHANGE_NAME = 'arcanebet_arcanebet-Submit'
      ROUTING_KEY = ENV['MTS_MQ_TICKET_CONFIRMATION']
      EXCHANGE_TYPE = :fanout

      protected

      def log_message
        log_job_message(
          :info, "MTS Validation requested for bets #{bet.id}"
        )
      end

      def message
        @message ||= ::Mts::Messages::ValidationRequest.new([bet])
      end

      def formatted_message
        message.to_formatted_hash.to_json
      end

      def update_bet
        bet.update(validation_ticket_id: message.ticket_id,
                   validation_ticket_sent_at: Time.zone.now)
      end
    end
  end
end
