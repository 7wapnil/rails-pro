# frozen_string_literal: true

module EveryMatrix
  class Category < ApplicationRecord
    self.table_name = :every_matrix_categories

    has_many :play_item_categories, dependent: :destroy
    has_many :play_items,
             through: :play_item_categories,
             foreign_key: :every_matrix_category_id

    default_scope { order(:position) }

    enum kind: {
      casino: CASINO_TYPE = 'casino',
      live_casino: TABLE_TYPE = 'live_casino'
    }

    enum platform_type: {
      desktop: DESKTOP = 'desktop',
      mobile: MOBILE = 'mobile'
    }

    CASINO_DESKTOP = 'casino-desktop'
    LIVE_CASINO_DESKTOP = 'live-casino-desktop'
    CASINO_MOBILE = 'casino-mobile'
    LIVE_CASINO_MOBILE = 'live-casino-mobile'
  end
end
