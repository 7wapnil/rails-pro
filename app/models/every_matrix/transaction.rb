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

    self.table_name = 'every_matrix_transactions'

    belongs_to :wallet_session, class_name: 'EveryMatrix::WalletSession'
    belongs_to :customer
    has_one :play_item, through: :wallet_session
    belongs_to :customer_bonus, optional: true

    has_one :entry_request, as: :origin
    has_one :entry, as: :origin

    has_one :wallet, through: :wallet_session
    has_one :currency, through: :wallet
    has_one :vendor, through: :play_item
    has_one :content_provider, through: :play_item

    def wager
      Wager.where(round_id: round_id).order(:created_at).first
    end
  end
end
