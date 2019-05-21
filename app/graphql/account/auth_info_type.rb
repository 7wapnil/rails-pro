module Account
  AuthInfoType = GraphQL::ObjectType.define do
    name 'AuthInfo'

    field :isSuspicious, !types.Boolean, property: :suspicious_login?
  end
end
