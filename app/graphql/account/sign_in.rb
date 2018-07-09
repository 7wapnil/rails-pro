module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      username = args[:input][:username]
      customer = Customer.find_for_authentication(username: username)

      if customer&.valid_password?(args[:input][:password])
        resolve(customer)
      else
        GraphQL::ExecutionError.new('Wrong email or password')
      end
    end

    private

    def resolve(customer)
      Audit::Service.call(target: 'Customer',
                          action: 'login',
                          origin_kind: :customer,
                          origin_id: customer.id)

      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
