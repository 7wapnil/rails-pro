class Entry < ApplicationRecord
  belongs_to :wallet

  validates :type, presence: true
end
