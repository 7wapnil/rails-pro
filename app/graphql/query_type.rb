QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :providers, function: Providers::ProvidersQuery.new
  field :wallets, function: Wallets::WalletsQuery.new
  field :currencies, function: Currencies::CurrencyQuery.new
  field :titles, function: Titles::TitlesQuery.new
  field :esportEvents, function: Events::BySport::EsportEventsQuery.new
  field :sportEvents, function: Events::BySport::SportEventsQuery.new
  field :tournamentEvents, function: Events::BySport::TournamentEventsQuery.new
  field :eventContexts, function: Events::ContextsQuery.new
  field :event, function: Events::EventQuery.new
  field :markets, function: Events::MarketsQuery.new
  field :documents, function: Documents::DocumentsQuery.new
  field :user, function: Account::UserQuery.new
  field :authInfo, function: Account::AuthInfoQuery.new
  field :verifyPasswordToken,
        function: Account::VerifyPasswordToken::Resolver.new
  field :bets, function: Betting::BetsQuery.new
  field :transactions, function: Transactions::TransactionsQuery.new
  field :customerBonuses, function: CustomerBonuses::CustomerBonusesQuery.new
  field :depositMethods, function: ::Payments::Deposits::PaymentMethodsQuery.new
end
