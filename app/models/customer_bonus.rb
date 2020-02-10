# frozen_string_literal: true

class CustomerBonus < ApplicationRecord
  include StateMachines::CustomerBonusStateMachine
  # TODO: replace this Callback with a direct call inside bonus related services
  after_commit :notify_application, on: %i[create update]

  default_scope { order(:created_at) }

  enum kind: Bonus.kinds

  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, -> { with_deleted }, class_name: Bonus.name
  belongs_to :activation_entry, class_name: Entry.name,
                                foreign_key: :entry_id,
                                optional: true

  has_one :currency, through: :wallet
  has_many :bets
  has_many :wagers, class_name: EveryMatrix::Wager.name
  has_many :entries, as: :origin

  has_one :cancellation_entry,
          -> { bonus_cancellation },
          as: :origin,
          class_name: Entry.name
  has_one :expiration_entry,
          -> { bonus_expiration },
          as: :origin,
          class_name: Entry.name
  has_one :loss_entry,
          -> { bonus_loss },
          as: :origin,
          class_name: Entry.name

  attr_reader :amount

  def loggable_attributes
    { code: code }
  end

  def self.customer_history(customer)
    includes(:activation_entry).where(customer: customer)
  end

  def active_until_date
    return expires_at unless activated_at

    activated_at.to_date + valid_for_days
  end

  def time_exceeded?
    return false unless active? && activated_at

    Time.zone.today >= active_until_date
  end

  private

  def notify_application
    WebSocket::Client.instance.trigger_customer_bonus_update(self)
  end
end
