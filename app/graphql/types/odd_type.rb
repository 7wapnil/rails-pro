Types::OddType = GraphQL::ObjectType.define do
  name 'Odd'

  field :id, !types.ID
  field :name, !types.String
end
