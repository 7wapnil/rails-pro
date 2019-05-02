Types::EventStateType = GraphQL::ObjectType.define do
  name 'EventState'

  field :id, types.ID
  field :status_code, types.Int
  field :status, types.String
  field :score, types.String
  field :time, types.String
  field :finished, types.Boolean
end
