# frozen_string_literal: true

module EveryMatrix
  class RecommendedGamesRelationship < ApplicationRecord
    self.table_name = :every_matrix_recommended_games_relationships

    belongs_to :original_game, class_name: EveryMatrix::PlayItem.name
    belongs_to :recommended_game, class_name: EveryMatrix::PlayItem.name

    validates :original_game, uniqueness: { scope: :recommended_game }
    validates :recommended_game, uniqueness: { scope: :original_game }
  end
end
