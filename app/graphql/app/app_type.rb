module App
  AppType = GraphQL::ObjectType.define do
    name 'App'

    field :live_connected, !types.Boolean
    field :pre_live_connected, !types.Boolean
  end
end
