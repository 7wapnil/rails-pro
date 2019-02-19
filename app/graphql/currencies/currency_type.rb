module Currencies
  CurrencyType = GraphQL::ObjectType.define do
    name 'Currency'

    field :id, types.ID
    field :code, !types.String
    field :name, !types.String
    field :primary, !types.Boolean
  end
end
