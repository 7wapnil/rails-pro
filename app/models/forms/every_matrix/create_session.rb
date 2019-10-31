# frozen_string_literal: true

module Forms
  module EveryMatrix
    class CreateSession
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      attr_accessor :play_item_id,
                    :wallet_id,
                    :subject

      with_options if: :real_money_mode? do
        validates :subject, presence: true
        validates :wallet, presence: true
      end

      validates :play_item_id, presence: true

      def launch_url
        ::EveryMatrix::Requests::LaunchUrlBuilder.call(
          play_item: play_item,
          session_id: session&.id
        )
      end

      private

      def real_money_mode?
        wallet_id.present? && subject.present?
      end

      def wallet
        subject.wallets.find_by(id: wallet_id)
      end

      def session
        return unless real_money_mode?

        ::EveryMatrix::WalletSession.create!(
          wallet_id: wallet_id,
          play_item: play_item
        )
      end

      def play_item
        @play_item ||= ::EveryMatrix::PlayItem.find(play_item_id)
      end
    end
  end
end
