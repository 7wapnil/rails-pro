module Account
  AuthInfoType = GraphQL::ObjectType.define do
    name 'AuthInfo'

    field :login_attempts,     !types.Int, property: :failed_attempts
    field :max_login_attempts, !types.Int do
      resolve ->(_obj, _args, _ctx) { LoginAttemptable::LOGIN_ATTEMPTS_CAP }
    end
  end
end
