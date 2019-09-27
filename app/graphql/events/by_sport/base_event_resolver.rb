module Events
  module BySport
    class BaseEventResolver
      SUPPORTED_CONTEXTS = [
        LIVE = 'live',
        UPCOMING = 'upcoming'
      ].freeze

      UPCOMING_CONTEXT_CACHE_TTL = 5.seconds
      LIVE_CONTEXT_CACHE_TTL = 2.seconds

      protected

      def base_query
        Event
          .joins(:title, :available_markets)
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

      def cached_for(interval)
        caching_key = "graphql-events-#{query_args.to_h}"

        Rails.cache.fetch(caching_key, expires_in: interval) do
          yield
        end
      end
    end
  end
end
