# frozen_string_literal: true

module Bets
  class PlacementForm
    include ActiveModel::Model

    attr_accessor :subject

    delegate :customer, to: :subject
    delegate :wallet, to: :customer

    def validate!
      check_if_odds_active!
      check_if_market_active!
      check_if_leg_odds_match_event_odds! unless subject.odds_change?
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

      raise ::Bets::RegistrationError, 'Bet placed with negative balance'
    end

    def check_if_odds_active!
      return if odds.all?(&:active?)

      raise ::Bets::RegistrationError,
            I18n.t('errors.messages.bet_odd_inactive')
    end

    def check_if_leg_odds_match_event_odds!
      subject.bet_legs.each do |leg|
        next if leg.odd_value == leg.odd.value

        raise ::Bets::RegistrationError,
              I18n.t('errors.messages.bet_odd_outdated')
      end
    end

    def limits_validation!
      raise NotImplementedError, "Define ##{__method__}"
    end

    def check_provider_connection!
      return if bet_producer_active?

      raise ::Bets::RegistrationError,
            I18n.t('errors.messages.provider_disconnected')
    end

    def bet_producer_active?
      !rejected_as_offline_upcoming_event &&
        !rejected_as_in_play_offline_event
    end

    def rejected_as_in_play_offline_event
      events.any?(&:in_play?) && Radar::Producer.live.unsubscribed?
    end

    def rejected_as_offline_upcoming_event
      events.any?(&:upcoming?) && Radar::Producer.prematch.unsubscribed?
    end

    def check_if_market_active!
      return if markets.all?(&:active?) &&
                events.all?(&:available?)

      raise ::Bets::RegistrationError, I18n.t('errors.messages.market_inactive')
    end

    def bet_legs
      @bet_legs ||= subject.bet_legs
                           .includes(odd: { market: :event })
    end

    def odds
      @odds ||= bet_legs.map(&:odd)
    end

    def markets
      @markets ||= odds.map(&:market)
    end

    def events
      @events ||= markets.map(&:event)
    end
  end
end
