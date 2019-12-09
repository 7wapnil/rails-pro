# frozen_string_literal: true

class BetLegDecorator < ApplicationDecorator
  delegate :odd, :event, :market, :title, to: :bet_leg, allow_nil: true
  delegate :name, to: :odd, allow_nil: true, prefix: true
  delegate :name, to: :market, allow_nil: true, prefix: true
  delegate :name, :start_at, to: :event, allow_nil: true, prefix: true

  def human_notification_message
    return notification_message unless notification_code

    I18n.t("bets.notifications.#{notification_code}",
           default: notification_message)
  end

  def display_status
    return I18n.t("settles.#{settlement_status}") if settlement_status

    I18n.t('statuses.pending')
  end
end
