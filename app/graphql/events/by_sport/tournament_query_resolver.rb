# frozen_string_literal: true

module Events
  module BySport
    class TournamentQueryResolver < BaseEventResolver
      def initialize(query_args)
        @query_args = query_args
        @tournament_id = query_args.id
      end

      def resolve
        @query = base_query
        @query = upcoming_and_live
        @query = query.distinct

        separate_by_time
      end

      private

      attr_reader :tournament_id, :query_args, :query

      def base_query
        super
          .joins(:event_scopes)
          .where(event_scopes: { id: tournament_id })
      end

      def upcoming_and_live
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.upcoming.or(query.in_play)
        end
      end

      def separate_by_time
        OpenStruct.new(
          live: query.in_play,
          upcoming: query.upcoming
        )
      end
    end
  end
end
