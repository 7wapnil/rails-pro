# frozen_string_literal: true

module Events
  module BySport
    class TournamentQueryResolver < BaseEventResolver
      UPCOMING_AND_LIVE = 'upcoming_and_live'

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

      def filter_by_context
        @context = UPCOMING_AND_LIVE if SUPPORTED_CONTEXTS.exclude?(context)

        @query = send(context)
      end

      def upcoming_and_live
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.upcoming.or(query.in_play)
        end
      end
    end
  end
end
