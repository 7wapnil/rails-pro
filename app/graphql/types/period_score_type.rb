Types::PeriodScoreType = GraphQL::ObjectType.define do
  name 'PeriodScore'

  field :score, !types.String
  field :status_code, !types.Int
  field :status, !types.String
end
