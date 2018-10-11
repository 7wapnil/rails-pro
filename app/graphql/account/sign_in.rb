module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      login = args[:input][:login]
      customer = Customer.find_for_authentication(login: login)

      if customer&.valid_password?(args[:input][:password])
        customer.update_tracked_fields!(@request)
        @current_customer = customer
        customer.log_event :customer_signed_in
        response(customer)
      else
        GraphQL::ExecutionError.new(
          I18n.t('errors.messages.wrong_login_credentials')
        )
      end
    end

    private

    def response(customer)
      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
