module Providers
  ProviderType = GraphQL::ObjectType.define do
    name 'Provider'

    field :id, !types.ID
    field :code, !types.String
    field :state, !types.String
  end
end
