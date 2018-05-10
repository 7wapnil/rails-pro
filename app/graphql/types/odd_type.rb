Types::OddType = GraphQL::ObjectType.define do
  name 'Odd'

  field :id, !types.ID
  field :name, !types.String
  field :odd_values, types[Types::OddValueType]
end
