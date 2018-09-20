module Events
  class EventsQuery < ::Base::Resolver
    include Base::Limitable

    type !types[EventType]

    description 'Get all events'

    argument :filter, EventFilter

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      filter = args[:filter] || {}
      query = Event
              .joins(markets: :odds)
              .where(start_at: (3.hours.ago..10.hours.from_now))
              .group('events.id')
              .order(:start_at)

      query = query.where(id: filter[:id]) if filter[:id]
      if filter[:titleId]
        query = query.where(title: Title.find_by(id: filter[:titleId]))
      end

      query = query.limit(args[:limit]) if args[:limit]
      query = query.in_play if filter[:inPlay]

      query
    end
  end
end
