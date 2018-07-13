module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      username = args[:input][:username]
      customer = Customer.find_for_authentication(username: username)

      if customer&.valid_password?(args[:input][:password])
        @current_customer = customer
        log_record_event :customer_signed_in, customer
        response(customer)
      else
        GraphQL::ExecutionError.new('Wrong email or password')
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
