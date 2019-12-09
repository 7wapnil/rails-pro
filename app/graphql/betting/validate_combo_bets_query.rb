# frozen_string_literal: true

module Betting
  class ValidateComboBetsQuery < ::Base::Resolver
    type !types[::Betting::OddValidationType]

    description 'Validate odds for combo-bets'

    argument :odds, types[types.ID]

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      ::BetPlacement::ComboBetsOddsValidationService.call(args[:odds])
    end
  end
end
