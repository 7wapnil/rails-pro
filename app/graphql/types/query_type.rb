Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :match do
    type Types::MatchType
    description 'Get a match by id'
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) { Event.find(args['id']) }
  end

  field :matches, types[Types::MatchType] do
    description 'Get all matches'
    resolve ->(_obj, _args, _ctx) { Event.match.in_play }
  end
end
