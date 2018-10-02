module Events
  class MarketsQuery < ::Base::Resolver
    include Base::Limitable

    type !types[Types::MarketType]

    description 'Get all markets list'

    argument :id, types.ID
    argument :eventId, types.ID
    argument :priority, types.Int

    def auth_protected?
      false
    end

    def resolve(obj, args)
      event_id = obj&.id || args[:eventId]
      raise 'Event ID is required' unless event_id
      query = Market
              .joins(:odds)
              .where(event_id: event_id)
              .group('markets.id')
              .order(priority: :desc)
      query = query.where(id: args[:id]) if args[:id]
      query = query.where(priority: args[:priority]) if args[:priority]
      query = query.limit(args[:limit]) if args[:limit]
      query.all
    end
  end
end
