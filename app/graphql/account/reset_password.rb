module Account
  class ResetPassword < ::Base::Resolver
    argument :token, !types.String
    argument :password, !types.String
    argument :confirmation, !types.String

    type !types.Boolean

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Account::ResetPasswordService.call(
        args[:token],
        args[:password],
        args[:confirmation]
      )
    end
  end
end
