# frozen_string_literal: true

module EveryMatrix
  class Transaction < ApplicationRecord
    include ::EveryMatrix::StateMachines::TransactionStateMachine

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
    belongs_to :game_round,
               class_name: 'EveryMatrix::GameRound',
               primary_key: :external_id,
               foreign_key: :round_id
    has_one :play_item, through: :wallet_session
    belongs_to :customer_bonus, optional: true
    belongs_to :every_matrix_free_spin_bonus,
               class_name: 'EveryMatrix::FreeSpinBonus',
               optional: true
    belongs_to :play_item,
               optional: true,
               class_name: EveryMatrix::PlayItem.name

    has_one :entry_request, as: :origin
    has_one :entry, as: :origin

    has_one :wallet, through: :wallet_session
    has_one :currency, through: :wallet
    has_one :vendor, through: :play_item
    has_one :content_provider, through: :play_item

    has_one :wager, through: :game_round

    delegate :entry, to: :wager, allow_nil: true, prefix: true
  end
end
