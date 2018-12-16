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
      return false unless limits_validation_succeeded?

      return false unless provider_connected?

      return false unless entry_request_succeeded?

      true
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
      @entry = WalletEntry::AuthorizationService.call(entry_request)
      unless @entry_request.succeeded?
        @bet.register_failure!(@entry_request.result_message)
        return false
      end
      true
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
  end
end
