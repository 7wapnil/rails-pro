module Titles
  class TitlesQuery < ::Base::Resolver
    UPCOMING_FOR_TIME = 'upcoming_for_time'.freeze

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
              .with_active_events(limit_start_at: limit_start_at(args))
              .order(name: :asc)

      query = query.where(id: args[:id]) if args[:id]
      query = query.where(kind: args[:kind]) if args[:kind]
      query.all
    end

    private

    def limit_start_at(args)
      return unless args[:context] == UPCOMING_FOR_TIME

      Events::EventsQueryResolver::UPCOMING_DURATION.hours.from_now
    end
  end
end
