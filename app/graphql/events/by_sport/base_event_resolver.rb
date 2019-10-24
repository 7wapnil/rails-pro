module Events
  module BySport
    class BaseEventResolver
      SUPPORTED_CONTEXTS = [Event::LIVE, Event::UPCOMING].freeze

      protected

      def base_query
        Event
          .to_display
          .joins(join_events_to_tournaments_sql)
          .preload(:dashboard_markets, :competitors)
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

      def live
        query.in_play
      end
    end
  end
end
