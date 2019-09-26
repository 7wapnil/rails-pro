# frozen_string_literal: true

module Events
  module BySport
    class SportQueryResolver
      SUPPORTED_CONTEXTS = [
        LIVE = 'live',
        UPCOMING = 'upcoming'
      ].freeze

      UPCOMING_CONTEXT_CACHE_TTL = 5.seconds
      LIVE_CONTEXT_CACHE_TTL = 2.seconds

      def initialize(query_args)
        @query_args = query_args
        @context = query_args.context
        @title_id = query_args.titleId.to_i
      end

      def resolve
        @query = base_query
        @query = filter_by_title_id
        filter_by_context!

        query.distinct
      end

      private

      attr_reader :query_args, :context, :query, :title_id

      def base_query
        Event
          .joins(:title, :available_markets)
          .joins(join_events_to_tournaments_sql)
          .preload(:dashboard_markets, :competitors)
          .visible
          .active
          .order(:priority, :start_at)
          .where(titles: { kind: Title::SPORTS })
          .where(title_id: title_id)
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
      # #live, #upcoming (for_time)
      def filter_by_context!
        return context_not_supported! if SUPPORTED_CONTEXTS.exclude?(context)

        @query = send(context)
      end

      def context_not_supported!
        raise StandardError,
              I18n.t('errors.messages.graphql.events.context.invalid',
                     context: context,
                     contexts: SUPPORTED_CONTEXTS.join(', '))
      end

      def cached_for(interval)
        caching_key = "graphql-events-#{query_args.to_h}"

        Rails.cache.fetch(caching_key, expires_in: interval) do
          yield
        end
      end

      def live
        cached_for(LIVE_CONTEXT_CACHE_TTL) do
          query.in_play
        end
      end

      def upcoming
        @query = query.upcoming
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.where('events.start_at <= ?',
                      Event::UPCOMING_DURATION.hours.from_now)
        end
      end

      def filter_by_title_id
        query.where(title_id: title_id)
      end
    end
  end
end
