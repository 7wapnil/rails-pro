module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      input = args[:input]
      return unless input

      user = create_user! input
      OpenStruct.new(user: user,
                     token: JwtService.encode(id: user.id,
                                              username: user.username,
                                              email: user.email))
    end

    private

    def create_user!(input)
      Customer.create!(username: input[:username],
                       email: input[:email],
                       first_name: input[:first_name],
                       last_name: input[:last_name],
                       date_of_birth: input[:date_of_birth],
                       password: input[:password],
                       password_confirmation: input[:password_confirmation])
    end
  end
end
