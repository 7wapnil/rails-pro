module Account
  class UserQuery < ::Base::Resolver
    type Account::UserType
    mark_as_trackable

    def resolve(_obj, _args)
      @current_customer
    end
  end
end
