# frozen_string_literal: true

module Bets
  module SingleBets
    class PlacementForm < ::Bets::PlacementForm
      private

      def limits_validation!
        BetPlacement::BettingLimitsValidationService.call(subject)
        return if subject.errors.empty?

        raise ::Bets::RegistrationError,
              I18n.t('errors.messages.betting_limits')
      end
    end
  end
end
