Types::OddType = GraphQL::ObjectType.define do
  name 'Odd'

  field :id, !types.ID
  field :name, !types.String
  field :value, !types.Float
  field :status, !types.Int do
    resolve ->(obj, _args, _ctx) { Odd.statuses[obj.status] }
  end
end
