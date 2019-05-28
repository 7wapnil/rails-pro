# frozen_string_literal: true

module Bets
  class PlacementForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :event, :odd, :market, to: :subject

    def validate!
      check_if_odd_active! &&
        check_if_market_active! &&
        limits_validation! &&
        check_provider_connection!
    end

    private

    def check_if_odd_active!
      return true if odd.active?

      raise ::Bets::PlacementError, I18n.t('errors.messages.bet_odd_inactive')
    end

    def limits_validation!
      BetPlacement::BettingLimitsValidationService.call(subject)
      return true if subject.errors.empty?

      raise ::Bets::PlacementError, I18n.t('errors.messages.betting_limits')
    end

    def check_provider_connection!
      return true if bet_producer_active?

      raise ::Bets::PlacementError,
            I18n.t('errors.messages.provider_disconnected')
    end

    def bet_producer_active?
      !rejected_as_offline_upcoming_event &&
        !rejected_as_in_play_offline_event
    end

    def rejected_as_in_play_offline_event
      event.in_play? && Radar::Producer.live.unsubscribed?
    end

    def rejected_as_offline_upcoming_event
      event.upcoming? && Radar::Producer.prematch.unsubscribed?
    end

    def check_if_market_active!
      return true if market.active?

      raise ::Bets::PlacementError, I18n.t('errors.messages.market_inactive')
    end
  end
end
