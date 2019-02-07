module BetPlacement
  class SubmissionService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest::BET
    ENTRY_REQUEST_MODE = EntryRequest::SYSTEM

    def initialize(bet, impersonated_by = nil)
      @bet = bet
      @impersonated_by = impersonated_by
    end

    def call
      @bet.send_to_internal_validation!
      return @bet unless valid?

      @bet.finish_internal_validation_successfully! do
        @bet.send_to_external_validation!
      end
      @bet
    rescue StandardError => e
      @bet.register_failure!(e.message)
      raise e
    end

    private

    def valid?
      limits_validation_succeeded? &&
        provider_connected? &&
        !market_suspended? &&
        entry_request_succeeded?
    end

    def limits_validation_succeeded?
      BetPlacement::BettingLimitsValidationService.call(@bet)
      unless @bet.errors.empty?
        @bet.register_failure!(I18n.t('errors.messages.betting_limits'))
        return false
      end
      true
    end

    def provider_connected?
      return true if bet_producer_active?

      @bet.register_failure!(I18n.t('errors.messages.provider_disconnected'))
      false
    end

    def bet_producer_active?
      event = @bet.event

      !(
          rejected_as_offline_upcoming_event(event) ||
            rejected_as_in_play_offline_event(event)
        )
    end

    def rejected_as_in_play_offline_event(event)
      event.in_play? && Radar::Producer.live.unsubscribed?
    end

    def rejected_as_offline_upcoming_event(event)
      event.upcoming? && Radar::Producer.prematch.unsubscribed?
    end

    def entry_request_succeeded?
      real_amount = amount_calculations[:real_money]
      error_msg = I18n.t('errors.messages.real_money_blank_amount')
      raise(ArgumentError, error_msg) if real_amount.nil? || real_amount.zero?

      BalanceRequestBuilders::Bet.call(entry_request, amount_calculations)
      @entry = WalletEntry::AuthorizationService.call(entry_request)
      unless @entry_request.succeeded?
        @bet.register_failure!(@entry_request.result_message)
        return false
      end
      true
    end

    def amount_calculations
      @amount_calculations ||= begin
        BalanceCalculations::BetWithBonus.call(@bet, ratio)
      end
    end

    def wallet
      @wallet ||= Wallet.find_or_create_by(customer_id: @bet.customer_id,
                                           currency_id: @bet.currency_id)
    end

    def ratio
      return 1.0 unless @bet.customer_bonus&.applied?

      wallet.ratio_with_bonus
    end

    def entry_request
      @entry_request ||= EntryRequest.create!(
        amount: @bet.amount,
        currency: @bet.currency,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @impersonated_by || @bet.customer,
        customer: @bet.customer,
        origin: @bet,
        comment: @impersonated_by ? I18n.t('impersonation_comment') : nil
      )
    end

    def market_suspended?
      @bet.market.suspended?
    end
  end
end
