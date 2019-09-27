# frozen_string_literal: true

module Events
  module BySport
    class TournamentQueryResolver < BaseEventResolver
      def initialize(query_args)
        @query_args = query_args
        @tournament_id = query_args.id
        @context = query_args.context
      end

      def resolve
        @query = base_query
        filter_by_context
        query.distinct
      end

      private

      attr_reader :tournament_id, :query_args, :query, :context

      def base_query
        super
          .joins(:event_scopes)
          .where(event_scopes: { id: tournament_id })
      end

      def cache_data
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) { query.upcoming }
        cached_for(LIVE_CONTEXT_CACHE_TTL)     { query.live }
      end

      def separate_by_time
        OpenStruct.new(
          upcoming: query.upcoming,
          live: query.in_play
        )
      end

      def filter_by_context
        @context = 'upcoming_and_live' if SUPPORTED_CONTEXTS.exclude?(context)

        @query = send(context)
      end

      def context_not_supported!
        raise StandardError,
              I18n.t('errors.messages.graphql.events.context.invalid',
                     context: context,
                     contexts: SUPPORTED_CONTEXTS.join(', '))
      end

      def live
        cached_for(LIVE_CONTEXT_CACHE_TTL) do
          query.in_play
        end
      end

      def upcoming
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.upcoming
        end
      end

      def upcoming_and_live
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.upcoming.or(query.in_play)
        end
      end
    end
  end
end
