module Betting
  class Place < ::Base::Resolver
    type types[BetType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      args[:bets].map do |bet_payload|
        BetPlacement::SubmissionService.call(create_bet(bet_payload),
                                             @impersonated_by)
      end
    end

    private

    def create_bet(bet_payload)
      Bet.create!(bet_attrs(bet_payload))
    end

    def bet_attrs(bet_payload)
      currency = Currency.find_by!(code: bet_payload[:currencyCode])
      amount = bet_payload[:amount]
      bonus = applicable_bonus
      {
        customer: @current_customer,
        odd: Odd.find(bet_payload[:oddId]),
        currency: currency,
        amount: amount,
        odd_value: bet_payload[:oddValue],
        status: Bet::INITIAL,
        customer_bonus: bonus
      }
    end

    def applicable_bonus
      bonus = @current_customer.customer_bonus

      return bonus if bonus && !bonus.expired?
    end
  end
end
