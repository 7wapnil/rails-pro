module Events
  class EventsQuery < ::Base::Resolver
    include Base::Offsetable

    type !types[EventType]

    description 'Get all events'

    argument :filter, EventFilter
    argument :context, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EventsLoader.new(args).load
    end
  end
end
