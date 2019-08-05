# frozen_string_literal: true

class Entry < ApplicationRecord
  include EntryKinds

  default_scope { order(created_at: :desc) }

  belongs_to :wallet
  belongs_to :origin, polymorphic: true, optional: true
  belongs_to :customer_transaction, foreign_key: :origin_id, optional: true
  belongs_to :withdrawal, foreign_key: :origin_id, optional: true
  belongs_to :bet, foreign_key: :origin_id, optional: true
  belongs_to :entry_request, optional: true

  has_many :balance_entries, dependent: :destroy
  has_many :balances, through: :balance_entries

  has_one :currency, through: :wallet
  has_one :customer, through: :wallet

  has_one :bonus_balance_entry,
          -> { bonus },
          class_name: BalanceEntry.name
  has_one :real_money_balance_entry,
          -> { real_money },
          class_name: BalanceEntry.name

  delegate :code, to: :currency, prefix: true

  validates :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }

  validates_with EntryAmountValidator

  scope :recent, -> { where(created_at: recent_scope) }

  # Hack to avoid collision after joins for sales report
  scope :positive, -> { where(amount: [0..Float::INFINITY]) }

  class << self
    def recent_scope
      Time.zone.yesterday.beginning_of_day..Time.zone.yesterday.end_of_day
    end
  end
end
