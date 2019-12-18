# frozen_string_literal: true

class BetLegDecorator < ApplicationDecorator
  PENDING = 'pending'
  CANCELLED = 'cancelled'

  delegate :odd, :event, :market, :title, to: :bet_leg, allow_nil: true

  delegate :name, :active?,
           to: :odd, allow_nil: true, prefix: true
  delegate :name, :status, :visible?, :enabled?,
           to: :market, allow_nil: true, prefix: true
  delegate :name, :start_at, :available?,
           to: :event, allow_nil: true, prefix: true

  def human_notification_message
    return notification_message unless notification_code

    I18n.t("bets.notifications.#{notification_code}",
           default: notification_message)
  end

  def display_status
    return CANCELLED if cancelled_by_system?

    settlement_status || PENDING
  end
end
