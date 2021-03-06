# frozen_string_literal: true

module Mts
  module Publishers
    class BetValidation < MessagePublisher
      EXCHANGE_NAME = 'arcanebet_arcanebet-Submit'
      CONSUMER_EXCHANGE_NAME = 'arcanebet_arcanebet-Confirm'
      QUEUE_NAME = ENV['MTS_MQ_QUEUE_CONFIRM']
      ROUTING_KEY = ENV['MTS_MQ_TICKET_CONFIRMATION_RK']
      EXCHANGE_TYPE = :fanout

      protected

      def log_message
        log_job_message(:info, message: 'MTS Validation requested',
                               bet_id: bet.id)
      end

      def message
        @message ||= request_builder.new([bet])
      end

      def formatted_message
        message.to_formatted_hash.to_json
      end

      def update_bet
        bet.update(validation_ticket_id: message.ticket_id,
                   validation_ticket_sent_at: Time.zone.now)
      end

      def request_builder
        return ::Mts::Messages::ComboBetsValidationRequest if bet.combo_bets?

        ::Mts::Messages::SingleBetValidationRequest
      end
    end
  end
end
