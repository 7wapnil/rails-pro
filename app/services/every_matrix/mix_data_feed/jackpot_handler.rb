# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class JackpotHandler < MixDataFeed::BaseHandler
      private

      def deactivate_object!
        jackpot = EveryMatrix::Jackpot.find_by(external_id: payload['id'])

        return unless jackpot

        jackpot.destroy!

        Rails.logger.info(message: 'Jackpot removed',
                          jackpot_external_id: payload['id'])
      end

      def handle_update_message
        EveryMatrix::Jackpot
          .find_or_create_by(external_id: data['id'])
          .update(base_currency_amount: data['amounts']['EUR'] || 0)
      end
    end
  end
end
