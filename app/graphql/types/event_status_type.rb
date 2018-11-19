Types::EventStatusType = GraphQL::ObjectType.define do
  name 'EventStatus'

  field :id, !types.ID do
    resolve ->(obj, _args, _ctx) { obj['event_id'].to_i }
  end
  field :status_code, types.Int do
    resolve ->(obj, _args, _ctx) { obj['status_code'] }
  end
  field :status, types.String do
    resolve ->(obj, _args, _ctx) { obj['status'] }
  end
  field :score, types.String do
    resolve ->(obj, _args, _ctx) { obj['score'] }
  end
  field :time, types.String do
    resolve ->(obj, _args, _ctx) { obj['time'] }
  end
  field :period_scores, types[Types::PeriodScoreType] do
    resolve ->(obj, _args, _ctx) { obj['period_scores'] }
  end
  field :finished, !types.Boolean do
    resolve ->(obj, _args, _ctx) { obj['finished'] }
  end
end
