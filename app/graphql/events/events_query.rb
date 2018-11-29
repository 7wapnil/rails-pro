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
      query = Event
              .visible
              .joins(markets: :odds)
              .joins(:title)
              .group('events.id')
              .order(:priority)
              .order(:start_at)
              .select('events.*')

      filter_query(query, args)
    end

    private

    def filter_query(query, args)
      filter = args[:filter] || {}

      query = filter_by_id(query, filter[:id])
      query = filter_by_title(query, filter[:titleId])
      query = filter_by_title_kind(query, filter[:titleKind])
      query = filter_by_tournament(query, filter[:tournamentId])
      query = query.limit(args[:limit]) if args[:limit]
      query = query.in_play if filter[:inPlay]
      query = query.upcoming if filter[:upcoming]

      query
    end

    def filter_by_id(query, id)
      return query if id.nil?

      query.where(id: id)
    end

    def filter_by_title(query, title_id)
      return query if title_id.nil?

      query.where(title_id: title_id)
    end

    def filter_by_title_kind(query, title_kind)
      return query if title_kind.nil?

      query.where(titles: { kind: title_kind })
    end

    def filter_by_tournament(query, tournament_id)
      return query if tournament_id.nil?

      query
        .joins(:scoped_events)
        .where(scoped_events: { event_scope_id: tournament_id })
    end
  end
end
