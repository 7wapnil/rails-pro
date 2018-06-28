module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    type Account::AccountType

    def call(_obj, args, _ctx)
      input = args[:input]
      return unless input

      # TODO: 1. replace with Customer.create(input)
      #       2. remove #create_customer!
      customer = create_customer! input
      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end

    private

    def create_customer!(input)
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
