module BetPlacement
  class SubmissionService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:bet]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:sports_ticket]

    def initialize(bet)
      @bet = bet
    end

    def call
      @bet.send_to_internal_validation!
      return @bet unless limits_validation_succeeded?

      return @bet unless entry_request_succeeded?

      @bet.finish_internal_validation_successfully! do
        @bet.send_to_external_validation!
      end
      @bet
    end

    private

    def limits_validation_succeeded?
      BetPlacement::BettingLimitsValidationService.call(@bet)
      unless @bet.errors.empty?
        @bet.register_failure!(I18n.t('errors.messages.betting_limits'))
        return false
      end
      true
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
        initiator: @bet.customer,
        customer: @bet.customer,
        origin: @bet
      )
    end
  end
end
