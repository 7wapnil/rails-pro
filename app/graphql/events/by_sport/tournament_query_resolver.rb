# frozen_string_literal: true

module Events
  module BySport
    class TournamentQueryResolver
      UPCOMING_CONTEXT_CACHE_TTL = 5.seconds

      def initialize(query_args)
        @query_args = query_args
        @tournament_id = query_args.id
      end

      def resolve
        @query = base_query
        cache_data
        @query = query.distinct

        separate_by_time
      end

      private

      attr_reader :tournament_id, :query_args, :query

      def base_query
        Event
          .joins(:title, :available_markets)
          .joins(join_events_to_tournaments_sql)
          .preload(:dashboard_markets, :competitors)
          .visible
          .active
          .order(:priority, :start_at)
          .joins(:event_scopes)
          .where(event_scopes: { id: tournament_id })
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

      def cache_data
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) { query }
      end

      def cached_for(interval)
        caching_key = "graphql-events-#{query_args.to_h}"

        Rails.cache.fetch(caching_key, expires_in: interval) do
          yield
        end
      end

      def separate_by_time
        OpenStruct.new(
          upcoming: query.upcoming,
          live: query.in_play
        )
      end
    end
  end
end
