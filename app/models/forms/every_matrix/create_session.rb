# frozen_string_literal: true

module Forms
  module EveryMatrix
    class CreateSession
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      before_validation :set_wallet

      attr_accessor :wallet,
                    :wallet_id,
                    :subject

      validates :subject, presence: true
      validates :wallet, presence: true

      def session
        ::EveryMatrix::WalletSession.create!(wallet: wallet)
      end

      private

      def set_wallet
        @wallet = subject.wallets.find_by(id: wallet_id)
      end
    end
  end
end
