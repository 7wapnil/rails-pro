module Account
  AuthInfoType = GraphQL::ObjectType.define do
    name 'AuthInfo'

    field :is_suspicious, !types.Boolean, property: :suspicious_login?
    field :max_attempts, !types.Int do
      resolve ->(_obj, _args, _ctx) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }
    end
  end
end