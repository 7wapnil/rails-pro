# frozen_string_literal: true

class Currency < ApplicationRecord
  FIAT_CODES = %w[EUR USD INR ZAR].freeze
  CRYPTO_CODES = %w[BTC].freeze
  PRIMARY_CODE = 'EUR'
  PRIMARY_NAME = 'Euro'
  PRIMARY_RATE = 1
  CRYPTO_SCALE = 5
  FIAT_SCALE   = 2

  include Loggable

  has_many :entry_currency_rules
  has_many :wallets

  has_one :deposit_currency_rule,
          -> { where(kind: EntryKinds::DEPOSIT) },
          class_name: EntryCurrencyRule.name
  has_one :withdraw_currency_rule,
          -> { where(kind: EntryKinds::WITHDRAW) },
          class_name: EntryCurrencyRule.name

  enum kind: {
    fiat:   FIAT   = 'fiat',
    crypto: CRYPTO = 'crypto'
  }

  accepts_nested_attributes_for :entry_currency_rules

  validates :name, :code, presence: true
  validates :exchange_rate, numericality: { allow_nil: true }
  validates_associated :entry_currency_rules

  def self.build_default
    new(code: PRIMARY_CODE, name: PRIMARY_NAME, primary: true)
  end

  def self.primary
    by_code(PRIMARY_CODE)
  end

  def self.by_code(code)
    find_by(code: code)
  end

  def to_s
    code
  end

  def primary?
    code == PRIMARY_CODE
  end

  def loggable_attributes
    { id: id,
      code: code,
      name: name }
  end

  def scale
    return CRYPTO_SCALE if crypto?

    FIAT_SCALE
  end

  def self.primary_scale
    return FIAT_SCALE if FIAT_CODES.include?(PRIMARY_CODE)

    CRYPTO_SCALE
  end
end
