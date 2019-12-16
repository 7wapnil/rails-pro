# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusPlayItem < ApplicationRecord
    self.table_name = 'every_matrix_free_spin_bonus_play_items'

    belongs_to :free_spin_bonus,
               foreign_key: :every_matrix_free_spin_bonus_id,
               class_name: 'EveryMatrix::FreeSpinBonus'
    belongs_to :play_item,
               foreign_key: :every_matrix_play_item_id,
               class_name: 'EveryMatrix::PlayItem'
  end
end
