Types::ScopeType = GraphQL::ObjectType.define do
  name 'Scope'

  field :id, !types.ID
  field :name, !types.String
  field :kind, !types.String
  field :eventScopeId, types.ID, property: :event_scope_id
  field :position, types.Int
end
