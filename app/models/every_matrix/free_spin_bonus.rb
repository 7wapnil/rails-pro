# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonus < ApplicationRecord
    self.table_name = 'every_matrix_free_spin_bonuses'

    belongs_to :vendor,
               class_name: 'EveryMatrix::Vendor',
               foreign_key: :every_matrix_vendor_id
    has_many :free_spin_bonus_wallets,
             class_name: 'EveryMatrix::FreeSpinBonusWallet',
             foreign_key: :every_matrix_free_spin_bonus_id,
             inverse_of: :free_spin_bonus
    has_many :wallets, through: :free_spin_bonus_wallets
    has_many :free_spin_bonus_play_items,
             class_name: 'EveryMatrix::FreeSpinBonusPlayItem',
             foreign_key: :every_matrix_free_spin_bonus_id,
             inverse_of: :free_spin_bonus
    has_many :play_items, through: :free_spin_bonus_play_items
  end
end
