module Account
  class VerifyEmail < ::Base::Resolver
    argument :token, !types.String

    type Account::VerifyEmailType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      customer = Customer.find_by!(email_verification_token: args[:token])
      if customer.email_verified
        raise GraphQL::ExecutionError,
              I18n.t('errors.messages.email_verified')
      end

      customer.update(email_verified: true)
      OpenStruct.new(
        success: true,
        user_id: customer.id
      )
    end
  end
end
