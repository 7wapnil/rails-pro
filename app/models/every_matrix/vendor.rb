# frozen_string_literal: true

module EveryMatrix
  class Vendor < ApplicationRecord
    self.table_name = :every_matrix_vendors

    has_many :play_items, foreign_key: :every_matrix_vendor_id
  end
end
