module Mts
  module Messages
    class ValidationResponse
      SUPPORTED_VALIDATION_RESPONSE_VERSION = '2.3'.freeze

      attr_reader :message

      def initialize(input_json)
        @message = parse(input_json)
        raise NotImplementedError unless version ==
                                         SUPPORTED_VALIDATION_RESPONSE_VERSION
      end

      def version
        @message[:version]
      end

      def bets
        Bet.where(validation_ticket_id: ticket_id)
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
        message.dig(:result, :bet_details, 0, :selection_details, 0)
               .to_h
               .except(:selection_index)
               .to_json
      end

      def rejection_message
        message.dig(:result, :reason, :message)
      end

      def rejection_key
        Mts::Codes::SUBMISSION_ERROR_CODES[error_code]
      end

      private

      def parse(json)
        hash = JSON.parse(json)
        ::HashDeepFormatter
          .deep_transform_keys(hash) { |key| key.to_s.underscore.to_sym }
      end

      def error_code
        message.dig(:result, :reason, :code)
      end
    end
  end
end
