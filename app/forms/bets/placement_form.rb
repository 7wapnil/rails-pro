# frozen_string_literal: true

module Bets
  class PlacementForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :event, :odd, :market, :customer, to: :subject
    delegate :wallet, to: :customer

    def validate!
      check_if_odd_active!
      check_if_market_active!
      limits_validation!
      check_provider_connection!
      check_if_customer_balance_positive!
    end

    private

    def check_if_customer_balance_positive!
      return unless wallet
      return if wallet.real_money_balance >= 0 && wallet.bonus_balance >= 0

      ArcanebetMailer
        .with(customer: customer)
        .negative_balance_bet_placement
        .deliver_later

      raise ::Bets::PlacementError, 'Bet placed with negative balance'
    end

    def check_if_odd_active!
      return if odd.active?

      raise ::Bets::PlacementError, I18n.t('errors.messages.bet_odd_inactive')
    end

    def limits_validation!
      BetPlacement::BettingLimitsValidationService.call(subject)
      return if subject.errors.empty?

      raise ::Bets::PlacementError, I18n.t('errors.messages.betting_limits')
    end

    def check_provider_connection!
      return if bet_producer_active?

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
      return if market.active? && market.event.available?

      raise ::Bets::PlacementError, I18n.t('errors.messages.market_inactive')
    end
  end
end
