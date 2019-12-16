# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusWallet < ApplicationRecord
    self.table_name = 'every_matrix_free_spin_bonus_wallets'

    include EveryMatrix::StateMachines::FreeSpinBonusWalletStateMachine

    scope :with_error, -> { where(status: ERROR_STATUSES) }
    scope :in_progress, -> { where(status: IN_PROGRESS_STATUSES) }

    belongs_to :wallet
    belongs_to :free_spin_bonus,
               foreign_key: :every_matrix_free_spin_bonus_id,
               class_name: 'EveryMatrix::FreeSpinBonus'
    delegate :customer, to: :wallet
  end
end
