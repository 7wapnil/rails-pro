# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  include StateMachines::CustomerBonusStateMachine
  acts_as_paranoid

  default_scope { order(:created_at) }

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true
  belongs_to :entry, optional: true
  has_many :bets

  enum kind: Bonus.kinds

  attr_reader :amount

  def ended_at
    created_at + valid_for_days.days
  end

  def expired?
    deleted_at || ended_at < Time.zone.now
  end

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    with_deleted.where(customer: customer)
  end

  def activated?
    entry_id.present?
  end
end
