class Currency < ApplicationRecord
  include Loggable

  has_many :entry_currency_rules

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates_associated :entry_currency_rules

  scope :primary_currency, -> {
    where(primary: true)
      .first
  }

  def self.build_default
    new(code: 'EUR', name: 'Euro', primary: true)
  end

  def to_s
    code
  end

  def loggable_attributes
    { id: id,
      code: code,
      name: name }
  end
end
