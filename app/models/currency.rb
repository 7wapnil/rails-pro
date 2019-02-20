class Currency < ApplicationRecord
  include Loggable

  after_save :invalidate_cache

  has_many :entry_currency_rules
  has_many :wallets

  enum kind: {
    fiat:   FIAT   = 'fiat'.freeze,
    crypto: CRYPTO = 'crypto'.freeze
  }

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates_associated :entry_currency_rules

  def self.available_currency_codes
    %w[EUR BTC USD INR ZAR]
  end

  def self.build_default
    new(code: 'EUR', name: 'Euro', primary: true)
  end

  def self.primary
    find_by(primary: true)
  end

  def to_s
    code
  end

  def loggable_attributes
    { id: id,
      code: code,
      name: name }
  end

  private

  def invalidate_cache
    Rails.cache.delete(Currencies::CurrencyQuery::CACHE_KEY)
  end
end
