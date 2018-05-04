ArcanebetSchema = GraphQL::Schema.define do
  # Comment this out when you have a mutation type
  # There's a bug that breaks GraphiQL if
  # blank mutation is present in the schema

  # mutation(Types::MutationType)
  query(Types::QueryType)
end
