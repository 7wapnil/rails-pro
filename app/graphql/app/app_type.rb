module App
  AppType = GraphQL::ObjectType.define do
    name 'App'

    field :status, !types.String
    field :statuses, !types[types.String]
    field :live_connected, !types.Boolean
    field :pre_live_connected, !types.Boolean
  end
end
