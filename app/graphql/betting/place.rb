module Betting
  class Place < ::Base::Resolver
    type types[BetType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      response = []

      args[:bets].each do |bet_payload|
        odd = Odd.find(bet_payload[:oddId])
        currency = Currency.find_by!(code: bet_payload[:currency])

        request = EntryRequest.new(
          amount: bet_payload[:amount],
          currency: currency,
          kind: EntryRequest.kinds[:bet],
          mode: EntryRequest.modes[:cashier],
          initiator: @current_customer,
          customer: @current_customer,
          origin: odd
        )

        request.save!

        WalletEntry::Service.call(request)

        message = request.result ? request.result['message'] : nil

        response << OpenStruct.new(
          amount: request.amount,
          currency: request.currency.code,
          odd: odd,
          market: odd.market,
          status: request.status,
          message: message
        )
      end

      response
    end
  end
end
