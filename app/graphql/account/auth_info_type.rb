module Account
  AuthInfoType = GraphQL::ObjectType.define do
    name 'AuthInfo'

    field :is_suspected, !types.Boolean, property: :suspected_login?
  end
end
