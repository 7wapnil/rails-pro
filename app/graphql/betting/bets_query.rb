module Betting
  class BetsQuery < ::Base::Resolver
    type !types[BetType]

    description 'Get all bets'

    def auth_protected?
      false
    end

    def resolve(_obj, args)

    end

  end
end
