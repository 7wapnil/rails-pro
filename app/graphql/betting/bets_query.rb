# frozen_string_literal: true

module Betting
  class BetsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[BetType]
    decorate_with BetDecorator

    description 'Get bets list for customer'

    argument :kind, types.String
    argument :ids, types[types.ID]
    argument :settlement_status, types.String

    def resolve(_obj, args)
      BetsQueryResolver.new(args: args, customer: @current_customer).resolve
    end
  end
end
