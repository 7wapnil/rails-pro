module Account
  class SignIn < GraphQL::Function
    argument :input, !Account::AuthInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      input = args[:input]
      return unless input

      user = Customer.find_by(email: input[:email])

      return unless user
      # return unless user.authenticate(input[:password])

      OpenStruct.new(user: user,
                     token: JwtService.encode(id: user.id,
                                              username: user.username,
                                              email: user.email))
    end
  end
end
