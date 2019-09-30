# frozen_string_literal: true

module EveryMatrix
  class Transaction < ApplicationRecord
    self.table_name = 'em_transactions'

    belongs_to :em_wallet_session, class_name: 'EveryMatrix::WalletSession'
    belongs_to :customer

    has_one :entry_request, as: :origin

    delegate :wallet, to: :em_wallet_session
    delegate :currency, to: :wallet
  end
end
