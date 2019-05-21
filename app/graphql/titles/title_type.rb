module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :name, !types.String
    field :kind, !types.String
    field :position, !types.Int
    field :show_category_in_navigation, !types.Boolean
    field :event_scopes, !types[Types::ScopeType],
          property: :dashboard_event_scopes

    field :tournaments, !types[Types::ScopeType],
          property: :dashboard_tournaments
  end
end
