# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  include StateMachines::CustomerBonusStateMachine

  acts_as_paranoid

  default_scope { order(:created_at) }

  enum kind: Bonus.kinds

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: Bonus.name
  belongs_to :entry, optional: true
  has_many :bets

  attr_reader :amount

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    with_deleted.where(customer: customer)
  end
end
