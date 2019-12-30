# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class ForfeitBonusHandler < BaseRequestHandler
      URL_PATH = '/vendorbonus/{vendor}/ForfeitBonus'
      FORFEIT_COMMENT = 'Arcanebet forfeits FreeRound bonus'

      def call
        return unless wallet.every_matrix_user_id

        free_spin_bonus_wallet.send_to_forfeit!
        update_status_on_result!
        update_last_request(name: 'ForfeitBonus', body: body, result: result)

        result['Success']
      end

      private

      def update_status_on_result!
        return free_spin_bonus_wallet.forfeit! if result['Success']

        free_spin_bonus_wallet.forfeit_with_error!
      end

      def user_exists?
        wallet.every_matrix_user_id
      end

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
        #   "BonusSource": 2,
        #   "LoginName": "JakeK2",
        #   "Password": "eitu44ygh",
        #   "Comment": "EveryMatrix forfeits FreeRound bonus",
        #   "UserId": 3190258,
        #   "GameIds": [
        #   323
        #   ],
        #   "BonusId": "489484546",
        #   "DomainId": 1060
        # }

        {
          "DomainId": domain_id,
          "BonusSource": free_spin_bonus.bonus_source,
          "LoginName": api_login,
          "Password": api_password,
          "Comment": FORFEIT_COMMENT,
          "UserId": wallet_user_id,
          "GameIds": play_item_game_codes,
          "BonusId": free_spin_bonus.id
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
    end
  end
end
