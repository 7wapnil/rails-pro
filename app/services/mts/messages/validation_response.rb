# frozen_string_literal: true

module Mts
  module Messages
    class ValidationResponse
      SUPPORTED_VALIDATION_RESPONSE_VERSION = '2.3'

      attr_reader :message

      def initialize(input_json)
        @message = parse(input_json)

        raise NotImplementedError unless version_supported?
      end

      def version
        @message[:version]
      end

      def bet
        @bet ||= Bet.find_by!(validation_ticket_id: ticket_id)
      end

      def ticket_id
        result[:ticket_id]
      end

      def accepted?
        result[:status] == 'accepted'
      end

      def rejected?
        result[:status] == 'rejected'
      end

      def result
        @message[:result]
      end

      def rejection_json
        message.dig(:result, :bet_details, 0, :selection_details)
               .to_a
               .map(&method(:except_selection_index))
               .to_json
      end

      def rejection_message
        message.dig(:result, :reason, :message)
      end

      def rejection_key
        notification_code(error_code)
      end

      def rejection_details
        bet.bet_legs.order(id: :asc)
           .each_with_object({}).with_index do |(bet_leg, accumulator), index|
             reason = rejection_reason(index)
             next unless reason

             accumulator[bet_leg.id] = {
               notification_code: notification_code(reason[:code]),
               notification_message: reason[:message]
             }
           end
      end

      private

      def version_supported?
        version == SUPPORTED_VALIDATION_RESPONSE_VERSION
      end

      def parse(json)
        hash = JSON.parse(json)
        ::HashDeepFormatter
          .deep_transform_keys(hash) { |key| key.to_s.underscore.to_sym }
      end

      def except_selection_index(hash)
        hash.except(:selection_index)
      end

      def notification_code(code)
        Mts::Codes::SUBMISSION_ERROR_CODES
          .fetch(code, Mts::Codes::DEFAULT_EXCEPTION_KEY)
      end

      def error_code
        message.dig(:result, :reason, :code)&.to_i
      end

      def rejection_reason(index)
        message.dig(:result, :bet_details, 0, :selection_details)
               &.find { |details| details[:selection_index] == index }
               &.dig(:reason)
      end
    end
  end
end
