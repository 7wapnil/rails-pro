class Currency < ApplicationRecord
  has_many :entry_currency_rules

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates_associated :entry_currency_rules

  def self.build_default
    new(code: 'EUR', name: 'Euro')
  end

  def to_s
    code
  end
end
