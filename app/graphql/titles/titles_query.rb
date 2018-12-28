module Titles
  class TitlesQuery < ::Base::Resolver
    type !types[TitleType]

    description 'Get all titles'

    argument :id, types.ID
    argument :kind, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      query = Title
              .with_active_events
              .order(name: :asc)

      query = query.where(id: args[:id]) if args[:id]
      query = query.where(kind: args[:kind]) if args[:kind]
      query.all
    end
  end
end
