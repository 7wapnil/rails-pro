# frozen_string_literal: true

Types::EventScopeType = GraphQL::ObjectType.define do
  name 'EventScope'

  field :id, !types.ID
  field :name, !types.String
  field :slug, !types.String do
    resolve ->(obj, *) { obj.slug || obj.id }
  end
  field :kind, !types.String
  field :eventScopeId, types.ID, property: :event_scope_id
  field :position, types.Int
  field :title, Titles::TitleType
end
