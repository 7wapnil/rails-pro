class EntryCurrencyRule < ApplicationRecord
  include EntryKinds

  belongs_to :currency

  validates :kind, presence: true
  validates :kind, inclusion: { in: kinds.keys }
  validates :kind, uniqueness: { scope: :currency_id }
end
