# frozen_string_literal: true

module EntryRequests
  class BetPlacementService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
      @bet = entry_request.origin
    end

    def call
      bet.send_to_internal_validation!
      return unless valid_bet? && validate_entry_request!

      bet.finish_internal_validation_successfully! do
        bet.send_to_external_validation!
      end
    end

    private

    attr_reader :entry_request, :bet

    def valid_bet?
      limits_validation_succeeded? &&
        provider_connected? &&
        market_not_suspended?
    end

    def limits_validation_succeeded?
      BetPlacement::BettingLimitsValidationService.call(bet)
      return true if bet.errors.empty?

      bet.register_failure!(I18n.t('errors.messages.betting_limits'))
      false
    end

    def provider_connected?
      return true if bet_producer_active?

      bet.register_failure!(I18n.t('errors.messages.provider_disconnected'))
      false
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

    def market_not_suspended?
      return true unless bet.market.suspended?

      bet.register_failure!(I18n.t('errors.messages.market_suspended'))
      false
    end

    def validate_entry_request!
      return entry_request_failed! if entry_request.failed?
      return zero_amount! if entry_request.amount.zero?

      WalletEntry::AuthorizationService.call(entry_request)

      return true if entry_request.succeeded?

      bet.register_failure!(entry_request.result_message)
      false
    end

    def entry_request_failed!
      bet.register_failure!(I18n.t('errors.messages.entry_request_failed',
                                   bet_id: bet.id))
      false
    end

    def zero_amount!
      bet.register_failure!(I18n.t('errors.messages.real_money_blank_amount'))
      entry_request
        .register_failure!(I18n.t('errors.messages.real_money_blank_amount'))
    end
  end
end
