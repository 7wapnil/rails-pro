# frozen_string_literal: true

module Em
  class Result < ApplicationRecord
    self.table_name = 'em_results'

    belongs_to :em_wallet_session, class_name: 'Em::WalletSession'
    belongs_to :customer

    delegate :wallet, to: :em_wallet_session
    delegate :currency, to: :wallet
  end
end
