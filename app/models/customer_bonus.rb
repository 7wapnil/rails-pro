# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  include StateMachines::CustomerBonusStateMachine

  default_scope { order(:created_at) }

  enum kind: Bonus.kinds

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: Bonus.name
  belongs_to :balance_entry, optional: true, inverse_of: :customer_bonus
  has_one :entry, through: :balance_entry
  has_one :currency, through: :wallet
  has_many :bets

  attr_reader :amount

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    includes(:balance_entry).where(customer: customer)
  end

  def active_until_date
    return expires_at unless activated_at

    activated_at.to_date + valid_for_days
  end

  def time_exceeded?
    return false unless active? && activated_at

    Time.zone.today >= active_until_date
  end
end
