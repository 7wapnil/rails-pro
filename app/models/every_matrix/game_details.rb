# frozen_string_literal: true

module EveryMatrix
  class GameDetails < ApplicationRecord
    self.table_name = :every_matrix_game_details

    belongs_to :play_item, foreign_key: :play_item_id
  end
end
