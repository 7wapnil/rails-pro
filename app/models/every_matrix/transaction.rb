# frozen_string_literal: true

module EveryMatrix
  class Transaction < ApplicationRecord
    self.table_name = 'every_matrix_transactions'

    TYPES = {
      Wager: WAGER = 'EveryMatrix::Wager',
      Result: RESULT = 'EveryMatrix::Result',
      Rollback: ROLLBACK = 'EveryMatrix::Rollback'
    }.freeze

    DEBIT_TYPES = [WAGER].freeze
    CREDIT_TYPES = [RESULT, ROLLBACK].freeze

    belongs_to :wallet_session, class_name: 'EveryMatrix::WalletSession'
    belongs_to :customer
    has_one :play_item, through: :wallet_session
    belongs_to :customer_bonus, optional: true
    belongs_to :every_matrix_free_spin_bonus,
               class_name: 'EveryMatrix::FreeSpinBonus',
               optional: true

    has_one :entry_request, as: :origin
    has_one :entry, as: :origin
    has_one :play_item, through: :wallet_session

    has_one :wallet, through: :wallet_session
    has_one :currency, through: :wallet
    has_one :vendor, through: :play_item
    has_one :content_provider, through: :play_item

    has_one :wager,
            foreign_key: :round_id,
            primary_key: :round_id,
            class_name: 'EveryMatrix::Wager'

    delegate :entry, to: :wager, allow_nil: true, prefix: true
  end
end
