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

    def resolve(obj, args)
      event_id = obj&.id || args[:eventId]
      raise 'Event ID is required' unless event_id

      query = Market
              .visible
              .joins(:odds)
              .where(event_id: event_id)
              .group('markets.id')
              .order(priority: :asc)
      query = filter_by_category(query, args[:category])
      query = filter_by_id(query, args[:id])
      query = filter_by_priority(query, args[:priority])
      query = query.limit(args[:limit]) if args[:limit]
      query.all
    end

    private

    def filter_by_category(query, category)
      return query unless category

      query.where(category: category)
    end

    def filter_by_id(query, id)
      return query unless id

      query.where(id: id)
    end

    def filter_by_priority(query, priority)
      return query unless priority

      query.where(priority: priority)
    end
  end
end
