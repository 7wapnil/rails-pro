module Events
  class EventsQuery < ::Base::Resolver
    type !types[EventType]

    description 'Get all events'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      Event
        .joins(markets: :odds)
        .where(title: Title.find_by(name: 'Counter-Strike'))
        .where(start_at: (3.hours.ago..10.hours.from_now))
        .group('events.id')
        .order(:start_at)
    end
  end
end
