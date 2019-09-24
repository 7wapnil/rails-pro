# frozen_string_literal: true

module Events
  class ContextsQueryResolver
    def initialize(query_args)
      @query_args = query_args
      @contexts = query_args.contexts
    end

    def resolve
      @contexts.map do |context|
        args = OpenStruct.new(filter: @query_args.filter, context: context)
        OpenStruct.new(
          context: context,
          show: EventsQueryResolver.new(args).resolve.any?
        )
      end
    end
  end
end
