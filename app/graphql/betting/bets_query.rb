module Betting
  class BetsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[BetType]
    decorate_with BetDecorator

    description 'Get all bets'

    argument :kind, types.String

    def resolve(_obj, args)
      query = Bet
              .where(customer: @current_customer)
              .order(created_at: :desc)
      if args[:kind]
        query = query.joins(odd: { market: { event: :title } })
                     .where('titles.kind = ?', args[:kind])
      end

      query.all
    end
  end
end
