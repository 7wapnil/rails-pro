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

    def bet_attrs(bet_payload) # rubocop:disable Metrics/MethodLength
      currency = Currency.find_by!(code: bet_payload[:currencyCode])
      amount = bet_payload[:amount]
      base_attrs = {
        customer: @current_customer,
        odd: Odd.find(bet_payload[:oddId]),
        currency: currency,
        amount: amount,
        odd_value: bet_payload[:oddValue],
        status: Bet::INITIAL
      }
      bonus = applicable_bonus(bet_payload)

      return base_attrs unless bonus

      wallet = @current_customer.wallets.where(currency: currency).first
      ratio = wallet.current_ratio
      base_attrs.merge(ratio: ratio, customer_bonus: bonus)
    end

    def applicable_bonus(bet_payload)
      odd_value = bet_payload[:oddValue]
      bonus = @current_customer.customer_bonus

      return unless bonus

      bonus unless bonus.expired? || odd_value < bonus.min_odds_per_bet
    end
  end
end
