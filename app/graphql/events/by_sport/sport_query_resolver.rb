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
        @query = filter_by_title_id
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
        cached_for(LIVE_CONTEXT_CACHE_TTL) do
          query.in_play
        end
      end

      def upcoming
        cached_for(UPCOMING_CONTEXT_CACHE_TTL) do
          query.upcoming.where('events.start_at <= ?',
                      Event::UPCOMING_DURATION.hours.from_now)
        end
      end

      def filter_by_title_id
        query.where(title_id: title_id)
      end
    end
  end
end
