module Account
  class AuthInfoQuery < ::Base::Resolver
    FIRST_LOGIN_ATTEMPT = 1

    type Account::AuthInfoType

    argument :login, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Customer.find_for_authentication(login: args[:login]) ||
        not_existing_user
    end

    private

    def not_existing_user
      Customer.new(failed_attempts: FIRST_LOGIN_ATTEMPT)
    end
  end
end
