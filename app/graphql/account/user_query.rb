module Account
  class UserQuery < ::Base::Resolver
    type Account::UserType

    def resolve(_obj, _args)
      @current_customer
    end
  end
end
