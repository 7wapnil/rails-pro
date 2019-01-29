module Events
  class EventsQuery < ::Base::Resolver
    include Base::Limitable
    include Base::Offsetable

    type !types[EventType]

    description 'Get all events'

    argument :filter, EventFilter
    argument :context, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      query = EventsLoader.new(args).load
      # TODO: remove limit and offset
      query = query.offset(args[:offset]) if args[:offset]
      query.limit(args[:limit]) if args[:limit]
    end
  end
end
