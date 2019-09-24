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

  has_one :currency, through: :wallet
  has_one :customer, through: :wallet

  delegate :code, to: :currency, prefix: true

  validates :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }

  validates_with EntryAmountValidator

  scope :confirmed, -> { where.not(confirmed_at: nil) }
end
