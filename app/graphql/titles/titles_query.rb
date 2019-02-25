module Titles
  class TitlesQuery < ::Base::Resolver
    type !types[TitleType]

    description 'Get all titles'

    argument :id, types.ID
    argument :kind, types.String
    argument :context, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      query = Title
              .with_active_events(active_events_query_arguments(args))
              .order(name: :asc)

      query = query.where(id: args[:id]) if args[:id]
      query = query.where(kind: args[:kind]) if args[:kind]
      query.all
    end

    private

    def active_events_query_arguments(args)
      limit_start_at = nil
      if args[:context] == 'upcoming_for_time'
        limit_start_at =
          Events::EventsQueryResolver::UPCOMING_DURATION.hours.from_now
      end

      { limit_start_at: limit_start_at }
    end
  end
end
