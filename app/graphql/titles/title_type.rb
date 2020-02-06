# frozen_string_literal: true

module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :externalName, !types.String, property: :external_name
    field :slug, !types.String do
      resolve ->(obj, *) { obj.slug || obj.id }
    end
    field :name, types.String
    field :shortName, types.String, property: :short_name
    field :kind, !types.String
    field :position, !types.Int
    field :showCategoryInNavigation, !types.Boolean,
          property: :show_category_in_navigation
    field :eventScopes, !types[Types::EventScopeType],
          property: :dashboard_event_scopes

    field :tournaments, !types[Types::EventScopeType],
          property: :dashboard_tournaments
  end
end
