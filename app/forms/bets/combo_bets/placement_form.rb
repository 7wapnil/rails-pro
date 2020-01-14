# frozen_string_literal: true

module Bets
  module ComboBets
    class PlacementForm < ::Bets::PlacementForm
      private

      def limits_validation!
        stake_limits_validation!
        combo_bets_rules_validation!
      end

      def stake_limits_validation!
        ::BetPlacement::BettingLimitsValidationService.call(subject)
        return if subject.errors.empty?

        raise ::Bets::RegistrationError,
              I18n.t('errors.messages.betting_limits')
      end

      def combo_bets_rules_validation!
        return if match_combo_bets_rules?

        raise ::Bets::RegistrationError,
              I18n.t('errors.messages.invalid_combo_bets')
      end

      def match_combo_bets_rules?
        ::BetPlacement::ComboBetsOddsValidationService
          .call(odds.map(&:id))
          .valid?
      end
    end
  end
end
