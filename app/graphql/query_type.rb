QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :wallets, function: Wallets::WalletsQuery.new
  field :titles, function: Titles::TitlesQuery.new
  field :title, function: Titles::TitleQuery.new
  field :events, function: Events::EventsQuery.new
  field :markets, function: Events::MarketsQuery.new
  field :market, function: Events::MarketQuery.new

  field :event do
    type Events::EventType
    description 'Get an event by id'
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) { Event.find(args['id']) }
  end
end
