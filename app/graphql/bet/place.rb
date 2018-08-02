module Bet
  class Place < ::Base::Resolver
    type types[BetType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      response = []

      args[:bets].each do |bet_payload|
        odd = Odd.find(bet_payload[:oddId])

        response << OpenStruct.new(
          amount: bet_payload[:amount],
          odd: odd,
          market: odd.market
        )
      end

      response
    end
  end
end
