# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonus < ApplicationRecord
    self.table_name = 'every_matrix_free_spin_bonuses'

    belongs_to :vendor,
               class_name: EveryMatrix::Vendor.name,
               foreign_key: :every_matrix_vendor_id
    has_many :free_spin_bonus_wallets,
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id,
             inverse_of: :free_spin_bonus
    has_many :initial_free_spin_bonus_wallets,
             -> { initial },
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id
    has_many :awarded_free_spin_bonus_wallets,
             -> { awarded },
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id
    has_many :forfeited_free_spin_bonus_wallets,
             -> { forfeited },
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id
    has_many :error_free_spin_bonus_wallets,
             -> { with_error },
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id
    has_many :in_progress_free_spin_bonus_wallets,
             -> { in_progress },
             class_name: EveryMatrix::FreeSpinBonusWallet.name,
             foreign_key: :every_matrix_free_spin_bonus_id
    has_many :wallets, through: :free_spin_bonus_wallets
    has_many :free_spin_bonus_play_items,
             class_name: EveryMatrix::FreeSpinBonusPlayItem.name,
             foreign_key: :every_matrix_free_spin_bonus_id,
             inverse_of: :free_spin_bonus
    has_many :play_items, through: :free_spin_bonus_play_items
  end
end
