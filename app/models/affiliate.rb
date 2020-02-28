class Affiliate < ApplicationRecord
  default_scope { order(:id) }

  validates :name,
            :b_tag,
            :sports_revenue_share,
            :casino_revenue_share,
            :cost_per_acquisition,
            presence: true

  validates :sports_revenue_share,
            :casino_revenue_share,
            :cost_per_acquisition,
            numericality: { greater_than_or_equal_to: 0 }
end
