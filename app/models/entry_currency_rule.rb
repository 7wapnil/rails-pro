class EntryCurrencyRule < ApplicationRecord
  include EntryKinds

  default_scope { order(kind: :asc) }

  belongs_to :currency

  validates :kind, :min_amount, :max_amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }
  validates :kind, uniqueness: { scope: :currency_id }
end
