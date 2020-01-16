# frozen_string_literal: true

module Forms
  module EveryMatrix
    class CreateSession
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      attr_accessor :play_item_slug,
                    :wallet_id,
                    :subject,
                    :country,
                    :device

      with_options if: :real_money_mode? do
        validates :subject, presence: true
        validates :wallet, presence: true
      end

      validates :play_item_slug, presence: true
      validate  :check_country

      def launch_url
        ::EveryMatrix::Requests::LaunchUrlBuilder.call(
          play_item: play_item,
          session_id: session&.id
        )
      end

      def play_item
        @play_item ||= ::EveryMatrix::PlayItem
                       .public_send(device)
                       .find_by!(slug: play_item_slug)
      end

      private

      def check_country
        return if play_item.restricted_territories.exclude?(country)

        errors.add(:country_code, I18n.t('errors.messages.unavailable_country'))
      end

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
    end
  end
end
