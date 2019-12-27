# frozen_string_literal: true

module EveryMatrix
  class JackpotTotalQuery < ::Base::Resolver
    type !JackpotType

    description 'Get jackpot total amount in EUR'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      OpenStruct.new(amount: EveryMatrix::Jackpot.total)
    end
  end
end
