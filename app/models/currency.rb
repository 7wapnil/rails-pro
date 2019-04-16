# frozen_string_literal: true

class Currency < ApplicationRecord
  CACHED_ALL_KEY = 'cache/currencies/cached_all'

  include Loggable

  after_commit :flush_cache

  has_many :entry_currency_rules
  has_many :wallets

  SUPPORTED_CODES = {
    euro: EUR = 'EUR',
    btc: BTC = 'BTC',
    usd: USD = 'USD',
    inr: INR = 'INR',
    ZAR: ZAR = 'ZAR'
  }.freeze

  enum kind: {
    fiat:   FIAT   = 'fiat',
    crypto: CRYPTO = 'crypto'
  }

  enum supported_code: SUPPORTED_CODES

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates :exchange_rate, numericality: { allow_nil: true }
  validates_associated :entry_currency_rules

  def self.available_currency_codes
    SUPPORTED_CODES.values
  end

  def self.build_default
    new(code: EUR, name: 'Euro', primary: true)
  end

  def self.primary
    find_by(primary: true)
  end

  def self.cached_all
    Rails.cache.fetch(CACHED_ALL_KEY, expires_in: 24.hours) do
      Currency.all
    end
  end

  def self.flush_cache
    Rails.cache.delete(CACHED_ALL_KEY)
  end

  delegate :flush_cache, to: :class

  def to_s
    code
  end

  def loggable_attributes
    { id: id,
      code: code,
      name: name }
  end
end
