# frozen_string_literal: true

module Events
  module BySport
    class EsportQueryResolver < BaseEventResolver
      def initialize(query_args)
        @query_args = query_args
        @context = query_args.context
        @title_id = query_args.titleId
      end

      def resolve
        @query = base_query
        @query = filter_by_title_id
        filter_by_context!

        query.distinct
      end

      private

      attr_reader :query_args, :context, :filter, :query, :title_id

      def base_query
        super
          .where(titles: { kind: Title::ESPORTS })
      end

      def upcoming
        query.upcoming
      end

      def filter_by_title_id
        return query unless title_id

        query.where(title_id: title_id)
      end
    end
  end
end
