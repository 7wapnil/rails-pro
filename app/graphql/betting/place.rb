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

      return base_attrs unless applicable_bonus?

      wallet = @current_customer.wallets.where(currency_id: currency.id).first
      bonus = @current_customer.customer_bonus
      ratio = wallet.current_ratio
      base_attrs.merge(ratio: ratio, customer_bonus_id: bonus.id)
    end

    def applicable_bonus?
      bonus = @current_customer.customer_bonus

      return false unless bonus

      !bonus.expired?
    end
  end
end
