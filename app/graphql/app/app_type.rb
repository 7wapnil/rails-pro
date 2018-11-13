module App
  AppType = GraphQL::ObjectType.define do
    name 'App'

    field :status, !types.String
    field :statuses, !types[types.String]
    field :flags, !types[types.String]
  end
end
