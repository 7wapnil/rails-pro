# frozen_string_literal: true

module EveryMatrix
  class TableDetails < ApplicationRecord
    self.table_name = :every_matrix_table_details

    belongs_to :table, foreign_key: :play_item_id
  end
end
