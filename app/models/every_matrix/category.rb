# frozen_string_literal: true

module EveryMatrix
  class Category < ApplicationRecord
    self.table_name = :every_matrix_categories

    has_many :play_item_categories
    has_many :play_items,
             through: :play_item_categories,
             foreign_key: :every_matrix_category_id

    default_scope { order(:position) }

    enum kind: {
      casino: CASINO_TYPE = 'casino',
      live_casino: TABLE_TYPE = 'live_casino'
    }
  end
end
