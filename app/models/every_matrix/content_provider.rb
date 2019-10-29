# frozen_string_literal: true

module EveryMatrix
  class ContentProvider < ApplicationRecord
    self.table_name = :every_matrix_content_providers

    has_many :play_items, foreign_key: :every_matrix_content_provider_id
  end
end
