module Account
  module VerifyPasswordToken
    class Resolver < ::Base::Resolver
      argument :token, !types.String

      type Account::VerifyPasswordToken::ResponseType

      def auth_protected?
        false
      end

      def resolve(_obj, args)
        token = reset_password_token(args[:token])
        customer = customer_from_token(token)

        return Response.invalid unless customer.persisted?
        return Response.expired unless customer.reset_password_period_valid?

        Response.valid
      end

      private

      def reset_password_token(original_token)
        Devise.token_generator.digest(
          Customer,
          :reset_password_token,
          original_token
        )
      end

      def customer_from_token(reset_password_token)
        Customer.find_or_initialize_with_error_by(
          :reset_password_token,
          reset_password_token
        )
      end
    end
  end
end
