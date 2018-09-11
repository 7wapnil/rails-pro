module Events
  class EventsQuery < ::Base::Resolver
    include Base::PaginationConcern

    type !types[EventType]

    description 'Get all events'

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Event
        .where(title: Title.find_by(name: 'Counter-Strike'))
        .where(start_at: (3.hours.ago..10.hours.from_now))
        .order(:start_at)
        .offset(args[:offset])
        .limit(args[:limit])
    end
  end
end
