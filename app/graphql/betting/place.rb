module Betting
  class Place < ::Base::Resolver
    type types[BetType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      args[:bets].map do |bet_payload|
        BetPlacement::SubmissionService.call(create_bet(bet_payload))
      end
    end

    private

    def create_bet(bet_payload)
      Bet.create!(
        customer: @current_customer,
        odd: Odd.find(bet_payload[:oddId]),
        currency: Currency.find_by!(code: bet_payload[:currencyCode]),
        amount: bet_payload[:amount],
        odd_value: bet_payload[:oddValue],
        status: Bet.statuses[:pending]
      )
    end
  end
end
