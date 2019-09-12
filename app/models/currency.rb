# frozen_string_literal: true

class Currency < ApplicationRecord
  FIAT_CODES = %w[EUR USD INR ZAR].freeze
  CRYPTO_CODES = %w[BTC].freeze
  PRIMARY_CODE = 'EUR'
  PRIMARY_RATE = 1

  include Loggable

  has_many :entry_currency_rules
  has_many :wallets

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
    new(code: PRIMARY_CODE, name: 'Euro', primary: true)
  end

  def self.primary
    find_by(primary: true)
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
end
