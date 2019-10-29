# frozen_string_literal: true

module EveryMatrix
  class PlayItemCategory < ApplicationRecord
    self.table_name = :every_matrix_play_item_categories

    belongs_to :play_item, foreign_key: :play_item_id
    belongs_to :category
  end
end
