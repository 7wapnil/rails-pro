class Currency < ApplicationRecord
  include Loggable

  has_many :entry_currency_rules
  has_many :wallets

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates_associated :entry_currency_rules

  def self.available_currency_codes
    %w[EUR BTC USD INR ZAR]
  end

  def self.build_default
    new(code: 'EUR', name: 'Euro', primary: true)
  end

  def self.primary_currency
    Currency.find_by(primary: true)
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
