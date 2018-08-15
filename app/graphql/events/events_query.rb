module Events
  class EventsQuery < ::Base::Resolver
    type !types[EventType]

    description 'Get all events'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      Event
        .where('start_at > ?', Date.yesterday.end_of_day)
        .order(:start_at)
        .all
    end
  end
end
