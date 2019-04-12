Types::ScopeType = GraphQL::ObjectType.define do
  name 'Scope'

  field :id, !types.ID
  field :name, !types.String
  field :kind, !types.String
  field :event_scope_id, types.ID
  field :position, types.Int
end
