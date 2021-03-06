# frozen_string_literal: true

QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :providers, function: Providers::ProvidersQuery.new
  field :wallets, function: Wallets::WalletsQuery.new
  field :currencies, function: Currencies::CurrencyQuery.new
  field :titles, function: Titles::TitlesQuery.new
  field :title, function: Titles::TitleQuery.new
  field :eventScope, function: Events::EventScopeQuery.new
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
  field :bonuses, function: CustomerBonuses::BonusesQuery.new
  field :validateComboBets, function: ::Betting::ValidateComboBetsQuery.new

  field :games, function: EveryMatrix::GamesQuery.new
  field :tables, function: EveryMatrix::TablesQuery.new
  field :categories, function: EveryMatrix::CategoriesQuery.new
  field :everyMatrixTransactions, function: ::EveryMatrix::TransactionsQuery.new
  field :gamesOverview, function: ::EveryMatrix::GamesOverviewQuery.new
  field :tablesOverview, function: ::EveryMatrix::TablesOverviewQuery.new
  field :recommendedGames, function: ::EveryMatrix::RecommendedGamesQuery.new
  field :searchCasinoGames, function: EveryMatrix::SearchCasinoGamesQuery.new
  field :gameProviders, function: EveryMatrix::GameProvidersQuery.new
  field :gamesByProvider, function: EveryMatrix::GamesByProviderQuery.new
  field :jackpotTotal, function: EveryMatrix::JackpotTotalQuery.new
  field :countryByRequest, function: Account::CountryByRequestQuery.new
end
