# frozen_string_literal: true

class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  has_one :currency, through: :wallet

  validates :kind, presence: true
  validates :amount, numericality: true

  delegate :currency_code, to: :wallet

  enum kind: {
    real_money: REAL_MONEY = 'real_money',
    bonus:      BONUS      = 'bonus'
  }

  def to_s
    "#{currency} #{I18n.t("kinds.#{kind}")} balance"
  end
end
