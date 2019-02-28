# frozen_string_literal: true

module EntryRequests
  class BetPlacementService < ApplicationService
    delegate :odd, :market, to: :bet

    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      bet.send_to_internal_validation!
      return unless validate

      bet.finish_internal_validation_successfully! do
        bet.send_to_external_validation!
      end
    end

    private

    attr_reader :entry_request, :bet

    def validate
      validate_bet! && validate_entry_request!
    rescue Bets::PlacementError => error
      bet.register_failure!(error.message)
      false
    end

    def validate_bet!
      check_if_odd_active! &&
        limits_validation! &&
        check_provider_connection! &&
        check_if_market_not_suspended!
    end

    def check_if_odd_active!
      return true if odd.active?

      raise Bets::PlacementError, I18n.t('errors.messages.bet_odd_inactive')
    end

    def limits_validation!
      BetPlacement::BettingLimitsValidationService.call(bet)
      return true if bet.errors.empty?

      raise Bets::PlacementError, I18n.t('errors.messages.betting_limits')
    end

    def check_provider_connection!
      return true if bet_producer_active?

      raise Bets::PlacementError,
            I18n.t('errors.messages.provider_disconnected')
    end

    def bet_producer_active?
      event = bet.event

      !(rejected_as_offline_upcoming_event(event) ||
        rejected_as_in_play_offline_event(event))
    end

    def rejected_as_in_play_offline_event(event)
      event.in_play? && Radar::Producer.live.unsubscribed?
    end

    def rejected_as_offline_upcoming_event(event)
      event.upcoming? && Radar::Producer.prematch.unsubscribed?
    end

    def check_if_market_not_suspended!
      return true unless market.suspended?

      raise Bets::PlacementError, I18n.t('errors.messages.market_suspended')
    end

    def validate_entry_request!
      return entry_request_failed! if entry_request.failed?
      return zero_amount! if entry_request.amount.zero?

      WalletEntry::AuthorizationService.call(entry_request)

      return true if entry_request.succeeded?

      raise Bets::PlacementError, entry_request.result_message
    end

    def entry_request_failed!
      raise Bets::PlacementError,
            I18n.t('errors.messages.entry_request_failed', bet_id: bet.id)
    end

    def zero_amount!
      entry_request
        .register_failure!(I18n.t('errors.messages.real_money_blank_amount'))

      raise Bets::PlacementError,
            I18n.t('errors.messages.real_money_blank_amount')
    end
  end
end
