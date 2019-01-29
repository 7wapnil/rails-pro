module Events
  class MarketsQuery < ::Base::Resolver
    include Base::Limitable

    type !types[Types::MarketType]

    description 'Get all markets list'

    argument :id, types.ID
    argument :eventId, types.ID
    argument :priority, types.Int
    argument :category, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Markets::QueryResolver.call(args: args)
    end
  end
end
