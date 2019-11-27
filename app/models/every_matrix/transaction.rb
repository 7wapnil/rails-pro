# frozen_string_literal: true

module EveryMatrix
  class Transaction < ApplicationRecord
    TYPES = {
      Wager: WAGER = 'EveryMatrix::Wager',
      Result: RESULT = 'EveryMatrix::Result',
      Rollback: ROLLBACK = 'EveryMatrix::Rollback'
    }.freeze

    DEBIT_TYPES = [WAGER].freeze
    CREDIT_TYPES = [RESULT, ROLLBACK].freeze

    self.table_name = 'em_transactions'

    belongs_to :em_wallet_session, class_name: 'EveryMatrix::WalletSession'
    belongs_to :customer

    has_one :entry_request, as: :origin
    has_one :entry, as: :origin

    delegate :wallet, to: :em_wallet_session
    delegate :currency, to: :wallet
  end
end
