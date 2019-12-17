# frozen_string_literal: true

class Bet < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include StateMachines::BetStateMachine

  PRECISION = 2
  VOIDED_ODD_VALUE = 1

  belongs_to :customer
  belongs_to :currency
  belongs_to :customer_bonus, optional: true

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin

  has_many :bet_legs, dependent: :destroy
  has_many :odds, through: :bet_legs
  has_many :markets, through: :odds
  has_many :events, through: :markets
  has_many :producers, through: :events
  has_many :titles, through: :events

  has_one :placement_entry,
          -> { unscoped.bet.order(:created_at) },
          class_name: Entry.name,
          as: :origin
  has_one :winning, -> { win }, class_name: Entry.name, as: :origin
  has_one :refund_entry, -> { refund }, class_name: Entry.name, as: :origin

  has_one :refund_request,
          -> { refund },
          class_name: EntryRequest.name,
          as: :origin

  has_one :placement_rollback_entry,
          -> { system_bet_cancel.where('entries.amount >= 0') },
          class_name: Entry.name,
          as: :origin
  has_one :winning_rollback_entry,
          -> { system_bet_cancel.where('entries.amount < 0') },
          class_name: Entry.name,
          as: :origin

  has_many :entry_requests, as: :origin, dependent: :nullify
  has_many :entries, as: :origin, dependent: :nullify
  has_many :tournaments, through: :bet_legs
  has_many :categories, through: :bet_legs

  has_many :scoped_bet_legs,
           -> do
             select('bet_legs.*')
               .with_category
               .with_tournament
               .with_sport
           end,
           class_name: BetLeg.name

  validates :void_factor,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 1
            },
            allow_nil: true

  scope :sort_by_winning_amount_asc,
        -> { with_winning_amount.order('winning_amount') }
  scope :sort_by_winning_amount_desc,
        -> { with_winning_amount.order('winning_amount DESC') }

  accepts_nested_attributes_for :bet_legs

  class << self
    def pending
      where(status: StateMachines::BetStateMachine::PENDING_STATUSES_MASK)
    end

    def from_regular_customers
      left_outer_joins(:customer).where(
        customers: { account_kind: Customer::REGULAR }
      )
    end

    def with_winning_amount
      sql = <<~SQL
        bets.*,
        (bets.amount * ROUND(
          EXP(SUM(LN(bet_legs.odd_value))
        ), 2)) AS winning_amount
      SQL
      select(sql).joins(:bet_legs).group('bets.id')
    end

    def ransackable_scopes(_auth_object = nil)
      %w[with_winning_amount]
    end

    def ransortable_attributes(auth_object = nil)
      super(auth_object) +
        %i[sort_by_winning_amount_asc sort_by_winning_amount_desc]
    end

    def expired_live
      timeout = ENV.fetch('MTS_LIVE_VALIDATION_TIMEOUT_SECONDS', 10).to_i
      condition = 'bets.validation_ticket_sent_at <= :expired_at
                         AND events.traded_live = true'
      sent_to_external_validation
        .joins(bet_legs: { odd: { market: %i[event] } })
        .where(condition,
               expired_at: timeout.seconds.ago)
    end

    def expired_prematch
      timeout = ENV.fetch('MTS_PREMATCH_VALIDATION_TIMEOUT_SECONDS', 3).to_i
      condition = 'bets.validation_ticket_sent_at <= :expired_at
                         AND events.traded_live = false'
      sent_to_external_validation
        .joins(bet_legs: { odd: { market: %i[event] } })
        .where(condition,
               expired_at: timeout.seconds.ago)
    end
  end

  def odd_value
    bet_legs
      .inject(1) do |product, leg|
        voided_leg = leg.cancelled_by_system? || leg.voided?
        leg_odd_value = voided_leg ? VOIDED_ODD_VALUE : leg.odd_value

        product * leg_odd_value
      end
      .round(PRECISION)
  end

  def potential_win
    amount * odd_value
  end

  def potential_loss
    amount
  end

  def win_amount
    return unless settlement_status
    return 0 unless won?

    (amount - refund_amount) * odd_value
  end

  def refund_amount
    return if settlement_status.nil?
    return 0 if void_factor.nil?

    amount * void_factor
  end

  def real_money_total
    entry_request&.succeeded? ? entry_request.real_money_amount : 0.0
  end

  def bonus_money_total
    entry_request&.succeeded? ? entry_request.bonus_amount : 0.0
  end
end
