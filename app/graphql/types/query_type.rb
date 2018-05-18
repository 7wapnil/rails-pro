Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :event do
    type Types::EventType
    description 'Get an event by id'
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) { Event.find(args['id']) }
  end

  field :events, types[Types::EventType] do
    description 'Get all events'

    argument :scope,
             types.String,
             prepare: ->(scope, _ctx) {
               # rubocop:disable Metrics/LineLength
               error_msg = 'Scope should be one of following values: (discipline, kind, event_scope)'
               # rubocop:enable Metrics/LineLength

               return scope if scope.in? %w[discipline kind event_scope]
               return GraphQL::ExecutionError.new(error_msg)
             }
    argument :query, types.String

    resolve ->(_obj, args, _ctx) {
      case args[:scope]
      when 'kind'
        Event.where(discipline: Discipline.select(:id).send(args[:query]))
      when 'discipline'
        Discipline.select(:id).find_by(name: args[:query]).events
      when 'event_scope'
        EventScope.select(:id).find_by(name: args[:query]).events
      else
        Event.all
      end
    }
  end
end
