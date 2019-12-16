# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class AwardBonusHandler < BaseRequestHandler
      URL_PATH = '/vendorbonus/{vendor}/AwardBonus'
      DATE_FORMAT = '%Y-%m-%dT23:59:59'

      def call
        return false unless wallet.every_matrix_user_id || create_user!

        free_spin_bonus_wallet.send_to_award!
        if result['Success']
          free_spin_bonus_wallet.award!
        else
          free_spin_bonus_wallet.award_with_error!
        end

        update_last_request(name: 'AwardBonus', body: body, result: result)

        result['Success']
      end

      private

      def create_user!
        CreateUserHandler.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
      end

      def url
        ENV['EVERY_MATRIX_FREE_SPINS_URL'] +
          URL_PATH.gsub(/{vendor}/, vendor.name)
      end

      def body
        # EXAMPLE
        # {
        #   "DomainId": "2067",
        #   "BonusSource": "2",
        #   "LoginName": "AnyOnStage",
        #   "Password": "AnyOnStage",
        #   "UserId": "14739",
        #   "GameIds": ["vs1fortunetree"],
        #   "BonusId": "bonus1",
        #   "NumberOfFreeRounds": 4,
        #   "FreeRoundsEndDate": "2020-01-01T23:25:00",
        #   "AdditionalParameters":{
        #
        #     "betPerLine": 1.0
        #   }
        # }

        {
          "DomainId": domain_id,
          "BonusSource": free_spin_bonus.bonus_source,
          "LoginName": api_login,
          "Password": api_password,
          "UserId": wallet_user_id,
          "GameIds": play_item_game_codes,
          "BonusId": free_spin_bonus.id,
          "NumberOfFreeRounds": free_spin_bonus.number_of_free_rounds,
          "FreeRoundsEndDate": free_rounds_end_date,
          "AdditionalParameters": additional_parameters
        }
      end

      def api_login
        ENV['EVERY_MATRIX_FREE_SPINS_LOGIN']
      end

      def api_password
        ENV['EVERY_MATRIX_FREE_SPINS_PASSWORD']
      end

      def wallet_user_id
        @wallet_user_id ||=
          wallet.every_matrix_user_id
      end

      def play_item_game_codes
        @play_item_game_codes ||=
          free_spin_bonus.play_items.pluck(:game_code).compact
      end

      def free_rounds_end_date
        @free_rounds_end_date ||=
          free_spin_bonus.free_rounds_end_date.strftime(DATE_FORMAT)
      end

      def additional_parameters
        @additional_parameters ||=
          JSON.parse(free_spin_bonus.additional_parameters)
      end
    end
  end
end
