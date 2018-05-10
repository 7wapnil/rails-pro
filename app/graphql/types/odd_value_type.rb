Types::OddValueType = GraphQL::ObjectType.define do
  name 'OddValue'

  field :id, !types.ID
  field :value, types.Float
  field :created_at, types.String
end
