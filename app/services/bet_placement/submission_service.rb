module BetPlacement
  class SubmissionService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest::BET
    ENTRY_REQUEST_MODE = EntryRequest::SPORTS_TICKET

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
    end

    private

    def valid?
      limits_validation_succeeded? &&
        provider_connected? &&
        entry_requests_succeeded?
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
      app_state = ApplicationState.instance
      connected = app_state.live_connected
      connected = app_state.pre_live_connected if @bet.event.traded_live
      return true if connected

      @bet.register_failure!(I18n.t('errors.messages.provider_disconnected'))
      false
    end

    def entry_request_succeeded?
      real_amount = amount_calculations[:real_money]
      error_msg = 'Real money amount can not be blank!'
      raise(ArgumentError, error_msg) if real_amount.nil? || real_amount.zero?

      @entry = WalletEntry::AuthorizationService.call(entry_request)
      unless @entry_request.succeeded?
        @bet.register_failure!(@entry_request.result_message)
        return false
      end
      true
    end

    def bonus_entry_request_succeeded?
      bonus_amount = amount_calculations[:bonus]

      return true if bonus_amount.zero?

      @bonus_entry = WalletEntry::AuthorizationService.call(bonus_entry_request,
                                                            :bonus)
      unless @bonus_entry_request.succeeded?
        @bet.register_failure!(@bonus_entry_request.result_message)
        return false
      end
      true
    end

    def entry_requests_succeeded?
      ActiveRecord::Base.transaction do
        entry_request_succeeded? && bonus_entry_request_succeeded?
      end
    end

    def amount_calculations
      @amount_calculations ||= BalanceCalculations::BetWithBonus.call(@bet)
    end

    def wallet
      @wallet ||= Wallet.find_by(customer_id: @bet.customer_id,
                                 currency_id: @bet.currency_id)
    end

    def entry_request
      @entry_request ||= EntryRequest.create!(
        amount: amount_calculations[:real_money],
        currency: @bet.currency,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @impersonated_by || @bet.customer,
        customer: @bet.customer,
        origin: @bet,
        comment: @impersonated_by ? I18n.t('impersonation_comment') : nil
      )
    end

    def bonus_entry_request
      @bonus_entry_request ||= EntryRequest.create(
        amount: amount_calculations[:bonus],
        currency: @bet.currency,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: @impersonated_by || @bet.customer,
        customer: @bet.customer,
        origin: @bet,
        comment: @impersonated_by ? I18n.t('impersonation_comment') : nil
      )
    end
  end
end
