Types::OddValueType = GraphQL::ObjectType.define do
  name 'OddValue'

  field :id, !types.ID
  field :value, types.Float
  field :created_at, types.String do
    resolve ->(obj, _args, _ctx) { obj.created_at&.iso8601 }
  end
end
