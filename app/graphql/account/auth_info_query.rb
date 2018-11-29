module Account
  class AuthInfoQuery < ::Base::Resolver
    type Account::AuthInfoType

    argument :login, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Customer.find_for_authentication(login: args[:login]) || Customer.new
    end
  end
end
