QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :event do
    type Events::EventType
    description 'Get an event by id'
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) { Event.find(args['id']) }
  end

  field :events, types[Events::EventType] do
    description 'Get all events'

    argument :scope,
             types.String,
             prepare: ->(scope, _ctx) {
               # rubocop:disable Metrics/LineLength
               error_msg = 'Scope should be one of following values: (title, kind, event_scope)'
               # rubocop:enable Metrics/LineLength

               return scope if scope.in? %w[title kind event_scope]
               return GraphQL::ExecutionError.new(error_msg)
             }
    argument :query, types.String

    resolve ->(_obj, args, _ctx) {
      case args[:scope]
      when 'kind'
        Event.where(title: Title.select(:id).send(args[:query]))
      when 'title'
        Title.select(:id).find_by(name: args[:query]).events
      when 'event_scope'
        EventScope.select(:id).find_by(name: args[:query]).events
      else
        Event.all
      end
    }
  end
end
