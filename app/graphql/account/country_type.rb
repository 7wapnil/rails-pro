# frozen_string_literal: true

module Account
  CountryType = GraphQL::ObjectType.define do
    name 'Country'

    field :country, types.String
  end
end
