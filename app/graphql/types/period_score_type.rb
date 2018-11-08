Types::PeriodScoreType = GraphQL::ObjectType.define do
  name 'PeriodScore'

  field :score, !types.String do
    resolve ->(obj, _args, _ctx) { obj['score'] }
  end
  field :status_code, !types.Int do
    resolve ->(obj, _args, _ctx) { obj['status_code'] }
  end
  field :status, !types.String do
    resolve ->(obj, _args, _ctx) { obj['status'] }
  end
end
