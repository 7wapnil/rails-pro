class EntryCurrencyRule < ApplicationRecord
  include EntryKinds

  belongs_to :currency
end
