# frozen_string_literal: true

class BetDecorator < ApplicationDecorator
  PRECISION = 2
  PENDING = 'pending'
  CANCELLED = 'cancelled'
  LOST = 'lost'

  delegate :code, to: :currency, allow_nil: true, prefix: true
  delegate :username, to: :customer, allow_nil: true, prefix: true
  delegate :code, to: :customer_bonus, allow_nil: true, prefix: true

  decorates_association :scoped_bet_legs, with: BetLegDecorator
  decorates_association :bet_legs, with: BetLegDecorator

  def display_status
    return LOST if unresolved_lost_bet?
    return PENDING if state_machine::PENDING_STATUSES_MASK.include?(status)
    return CANCELLED if state_machine::CANCELLED_STATUSES_MASK.include?(status)
    return settlement_status if state_machine::SETTLED_STATUSES_MASK
                                .include?(status)

    status
  end

  def amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def base_currency_amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def created_at(human: false)
    human ? l(super(), format: :long) : super()
  end

  def bet_settlement_status_achieved_at(human: false)
    return super() unless human

    super() ? l(super(), format: :long) : '-'
  end

  def winning_amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def human_notification_message
    return notification_message unless notification_code

    I18n.t("bets.notifications.#{notification_code}",
           default: notification_message)
  end

  def bet_type
    live? ? t('bets.bet_types.live') : t('bets.bet_types.prematch')
  end

  def bet_leg_collection
    bet_legs.map do |bet_leg|
      [
        "#{bet_leg.event.name} | #{bet_leg.market.name} | #{bet_leg.odd.name}",
        bet_leg.id
      ]
    end
  end

  private

  def unresolved_lost_bet?
    combo_bets? && lost? && pending_manual_settlement?
  end

  def state_machine
    StateMachines::BetStateMachine
  end

  def live?
    bet_legs.map(&:event).any? { |event| event.start_at < created_at }
  end
end
