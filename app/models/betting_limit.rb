class BettingLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :currency
  belongs_to :title, optional: true

  before_validation :set_primary_currency, on: :create

  validates :customer, :currency, presence: true
  validates :customer, uniqueness: { scope: :title }

  private

  def set_primary_currency
    self.currency ||= Currency.primary_currency
  end
end
