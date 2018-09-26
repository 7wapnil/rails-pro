QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :wallets, function: Wallets::WalletsQuery.new
  field :titles, function: Titles::TitlesQuery.new
  field :events, function: Events::EventsQuery.new
  field :markets, function: Events::MarketsQuery.new
  field :documents, function: Documents::DocumentsQuery.new
end
