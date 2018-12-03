QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :app, function: App::AppQuery.new
  field :wallets, function: Wallets::WalletsQuery.new
  field :titles, function: Titles::TitlesQuery.new
  field :events, function: Events::EventsQuery.new
  field :markets, function: Events::MarketsQuery.new
  field :documents, function: Documents::DocumentsQuery.new
  field :user, function: Account::UserQuery.new
  field :authInfo, function: Account::AuthInfoQuery.new
  field :bets, function: Betting::BetsQuery.new
end
