module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      input = args[:input]
      return unless input

      attributes = input.to_h.merge(origin_kind: :customer)
      customer = Customer.create!(attributes)
      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
