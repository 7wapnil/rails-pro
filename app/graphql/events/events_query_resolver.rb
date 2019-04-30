# frozen_string_literal: true

module Events
  class EventsQueryResolver # rubocop:disable Metrics/ClassLength
    LIVE = 'live'
    UPCOMING_CONTEXTS =
      %w[upcoming_for_time upcoming_limited upcoming_unlimited].freeze
    SUPPORTED_CONTEXTS = [LIVE, *UPCOMING_CONTEXTS].freeze
    UPCOMING_LIMIT = 16
    UPCOMING_DURATION = 6

    def initialize(query_args)
      @query_args = query_args
      @context = query_args.context
      @filter = OpenStruct.new(query_args.filter.to_h)
    end

    def resolve
      @query = base_query
      @query = filter_by_title_id
      @query = filter_by_title_kind
      @query = filter_by_event_scopes
      filter_by_context!
      query
    end

    private

    attr_reader :query_args, :context, :filter, :query

    def base_query
      Event
        .joins(:title)
        .joins(join_events_to_tournaments_sql)
        .preload(:dashboard_markets, :competitors)
        .visible
        .active
        .order(:priority, :start_at)
    end

    def join_events_to_tournaments_sql
      <<~SQL
        INNER JOIN "scoped_events" "t_scoped_events"
        ON "t_scoped_events"."event_id" = "events"."id"
        INNER JOIN "event_scopes" "t_event_scopes"
        ON "t_event_scopes"."id" = "t_scoped_events"."event_scope_id"
          AND "t_event_scopes"."kind" = 'tournament'
      SQL
    end

    # It tries to call:
    # #live, #upcoming_for_time, #upcoming_limited, #upcoming_unlimited
    def filter_by_context!
      return context_not_supported! if SUPPORTED_CONTEXTS.exclude?(context)

      @query = query.upcoming if UPCOMING_CONTEXTS.include?(context)
      @query = send(context)
    end

    def context_not_supported!
      raise StandardError,
            I18n.t('errors.messages.graphql.events.context.invalid',
                   context: context,
                   contexts: SUPPORTED_CONTEXTS.join(', '))
    end

    def live
      query.in_play
    end

    def upcoming_for_time
      query.where('events.start_at <= ?', UPCOMING_DURATION.hours.from_now)
    end

    def upcoming_limited
      query.where(id: limited_per_tournament_ids)
    end

    def limited_per_tournament_ids
      EventScope
        .select('events.id AS event_id')
        .joins(:scoped_events)
        .joins(join_tournaments_to_events_sql)
        .tournament
        .where(events: { id: query_ids })
        .pluck(:event_id)
    end

    def join_tournaments_to_events_sql
      <<~SQL
        JOIN events
        ON scoped_events.event_id = events.id AND events.id IN (
          SELECT events.id
          FROM events
          INNER JOIN scoped_events se
          ON se.event_id = events.id AND se.event_scope_id = event_scopes.id
          WHERE events.id IN (#{query_ids.join(', ').presence || 'NULL'})
          ORDER BY priority, start_at ASC
          LIMIT #{UPCOMING_LIMIT}
        )
      SQL
    end

    def query_ids
      @query_ids ||= query.ids
    end

    def upcoming_unlimited
      query
    end

    def filter_by_title_id
      return query unless filter.title_id

      query.where(title_id: filter.title_id)
    end

    def filter_by_title_kind
      return query unless filter.title_kind

      query.where(titles: { kind: filter.title_kind })
    end

    def filter_by_event_scopes
      return query if event_scope_ids.blank?

      query
        .eager_load(:event_scopes)
        .where(event_scopes: { id: event_scope_ids })
    end

    def event_scope_ids
      @event_scope_ids ||= [filter.category_id, filter.tournament_id].compact
    end
  end
end
