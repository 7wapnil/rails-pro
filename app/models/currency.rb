class Currency < ApplicationRecord
  has_many :entry_currency_rules

  validates :name, :code, presence: true
end
