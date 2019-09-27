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
        cache_data
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
    end
  end
end
