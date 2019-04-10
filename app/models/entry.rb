# frozen_string_literal: true

class Entry < ApplicationRecord
  include EntryKinds

  default_scope { order(created_at: :desc) }

  belongs_to :wallet
  belongs_to :origin, polymorphic: true, optional: true
  belongs_to :entry_request
  has_one :currency, through: :wallet
  has_many :balance_entries, dependent: :destroy
  has_one :customer, through: :wallet

  delegate :code, to: :currency, prefix: true

  validates :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }

  validates_with EntryAmountValidator
end
