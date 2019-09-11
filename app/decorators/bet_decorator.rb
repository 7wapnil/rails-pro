# frozen_string_literal: true

class BetDecorator < ApplicationDecorator
  PRECISION = 2
  PENDING = 'pending'
  CANCELLED = 'cancelled'

  delegate :code, to: :currency, allow_nil: true, prefix: true

  delegate :name, to: :odd, allow_nil: true, prefix: true

  delegate :name, to: :market, allow_nil: true, prefix: true

  delegate :name, :start_at, to: :event, allow_nil: true, prefix: true

  delegate :username, to: :customer, allow_nil: true, prefix: true

  delegate :code, to: :customer_bonus, allow_nil: true, prefix: true

  def display_status
    return PENDING if state_machine::PENDING_STATUSES_MASK.include?(status)
    return CANCELLED if state_machine::CANCELLED_STATUSES_MASK.include?(status)

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

  def actual_payout(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def human_notification_message
    return notification_message unless notification_code

    I18n.t("bets.notifications.#{notification_code}",
           default: notification_message)
  end

  def bet_type
    return unless event
    return t('bets.bet_types.live') if created_at > event_start_at

    t('bets.bet_types.prematch')
  end

  private

  def state_machine
    StateMachines::BetStateMachine
  end
end
