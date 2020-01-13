# frozen_string_literal: true

class Odd < ApplicationRecord
  enum status: {
    inactive: INACTIVE = 'inactive',
    active:   ACTIVE   = 'active'
  }

  belongs_to :market
  has_one :event, through: :market
  has_many :competitors, through: :event
  has_many :bet_legs
  has_many :bets, through: :bet_legs

  validates :name, :status, presence: true
  validates :value, presence: true,
                    on: :create,
                    if: proc { |odd| odd.active? }
  validates :value, numericality: { greater_than: 0 }, allow_nil: true
end
