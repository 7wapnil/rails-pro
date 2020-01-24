# frozen_string_literal: true

module EveryMatrix
  class Vendor < ApplicationRecord
    include BetterSluggable

    self.table_name = :every_matrix_vendors

    friendly_id :name, use: :sequentially_slugged

    has_many :play_items,
             foreign_key: :every_matrix_vendor_id,
             dependent: :destroy

    default_scope -> { order(:id) }

    scope :visible, -> { where(visible: true, external_status: ACTIVATED) }

    enum external_status: {
      activated: ACTIVATED = 'activated',
      deactivated: DEACTIVATED = 'deactivated'
    }
  end
end
