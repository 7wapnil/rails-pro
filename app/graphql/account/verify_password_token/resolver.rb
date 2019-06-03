module Account
  module VerifyPasswordToken
    class Resolver < ::Base::Resolver
      argument :token, !types.String

      type Account::VerifyPasswordToken::ResponseType

      def auth_protected?
        false
      end

      def resolve(_obj, args)
        customer = Devise::ResetPasswordToken::CustomerLoader.call(args[:token])

        return Response.invalid unless customer.persisted?
        return Response.expired unless customer.reset_password_period_valid?

        Response.valid
      end
    end
  end
end
