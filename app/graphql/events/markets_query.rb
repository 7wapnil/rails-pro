module Events
  class MarketsQuery < ::Base::Resolver
    include Base::Limitable

    type !types[Types::MarketType]

    description 'Get all markets list'

    argument :eventId, types.ID
    argument :priority, types.Int

    def auth_protected?
      false
    end

    def resolve(obj, args)
      event_id = obj&.id || args[:eventId]
      raise 'Event ID is required' unless event_id
      query = Market
              .where(event_id: event_id)
              .order(priority: :desc)
              .limit(args[:limit])
      query = query.where(priority: args[:priority]) if args[:priority]
      query.all
    end
  end
end
