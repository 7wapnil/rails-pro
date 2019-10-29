# frozen_string_literal: true

module Betting
  class BetsQuery < ::Base::Resolver
    include ::Base::Pagination

    type !types[BetType]
    decorate_with BetDecorator
    mark_as_trackable

    description 'Get bets list for customer'

    argument :kind, types.String
    argument :ids, types[types.ID]
    argument :settlementStatus, types.String
    argument :dateRange, types.String
    argument :excludedStatuses, types[::Bets::StatusEnum]

    def resolve(_obj, args)
      BetsQueryResolver.new(args: args, customer: @current_customer).resolve
    end
  end
end
