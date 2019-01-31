module Betting
  class Place < ::Base::Resolver
    type types[BetPlacementType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      args[:bets].map do |bet_payload|
        bet = create_bet(bet_payload)
        BetPlacement::SubmissionService.call(bet, @impersonated_by)

        OpenStruct.new(id: bet_payload[:oddId],
                       message: nil,
                       success: true,
                       bet: bet)

      rescue StandardError => e

        OpenStruct.new(id: bet_payload[:oddId],
                       message: e.message,
                       success: false)
      end
    end

    private

    def create_bet(bet_payload)
      Bet.create!(bet_attrs(bet_payload))
    end

    def bet_attrs(bet_payload)
      currency = Currency.find_by!(code: bet_payload[:currencyCode])
      amount = bet_payload[:amount]
      {
        customer: @current_customer,
        odd: Odd.find(bet_payload[:oddId]),
        currency: currency,
        amount: amount,
        odd_value: bet_payload[:oddValue],
        status: Bet::INITIAL,
        customer_bonus: @current_customer.active_bonus
      }
    end
  end
end
