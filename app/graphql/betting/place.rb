module Betting
  class Place < ::Base::Resolver
    type types[BetType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      args[:bets].map do |bet_payload|
        bet = Bet.create!(
          customer: @current_customer,
          odd: Odd.find(bet_payload[:oddId]),
          currency: Currency.find_by!(code: bet_payload[:currencyCode]),
          amount: bet_payload[:amount],
          odd_value: bet_payload[:oddValue]
        )

        BetPlacement::Service.call(bet)
      end
    end
  end
end
