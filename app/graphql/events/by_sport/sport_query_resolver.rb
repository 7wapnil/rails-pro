# frozen_string_literal: true

module Events
  module BySport
    class SportQueryResolver < BaseEventResolver
      def initialize(query_args)
        @query_args = query_args
        @context = query_args.context
        @title_id = query_args.titleId.to_i
      end

      def resolve
        @query = base_query
        filter_by_context!

        query.distinct
      end

      private

      attr_reader :query_args, :context, :query, :title_id

      def base_query
        super
          .where(titles: { kind: Title::SPORTS })
          .where(title_id: title_id)
      end

      # upcoming (for_time)
      def upcoming
        query.upcoming(limit_start_at: Event::UPCOMING_DURATION.hours.from_now)
      end
    end
  end
end
