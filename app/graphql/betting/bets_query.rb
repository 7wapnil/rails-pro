module Betting
  class BetsQuery < ::Base::Resolver
    type !types[BetType]

    description 'Get all bets'

    argument :kind, types.String

    def resolve(_obj, args)
      query = Bet
              .where(customer: @current_customer)
      if args[:kind]
        query = query.joins(odd: { market: { event: :title } })
                     .where('titles.kind = ?', args[:kind])
      end
      query.all
    end
  end
end
