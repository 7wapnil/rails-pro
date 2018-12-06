module Account
  AuthInfoType = GraphQL::ObjectType.define do
    name 'AuthInfo'

    field :is_suspicious, !types.Boolean, property: :suspicious_login?
  end
end
