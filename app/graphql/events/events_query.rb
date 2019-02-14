module Events
  class EventsQuery < ::Base::Resolver
    include Base::Offsetable
    # include Base::Pagination

    type !types[EventType]

    description 'Get all events'

    argument :filter, EventFilter
    argument :context, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EventsQueryResolver.new(args).resolve
    end
  end
end
