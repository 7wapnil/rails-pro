module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    argument :customer_data,
             Account::CustomerDataInput,
             default_value: nil

    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      input = args[:input]
      return unless input

      @customer = ::Customers::RegistrationService.call(input.to_h, @request)
      save_customer_data(args)
      token = JwtService.encode(id: customer.id,
                                username: customer.username,
                                email: customer.email)
      OpenStruct.new(user: customer,
                     token: token)
    end

    attr_reader :customer

    private

    def save_customer_data(args)
      customer_data = args[:customer_data]&.to_h
      return if customer_data.blank?

      CustomerData.create(customer_data.merge(customer: customer,
                                              ip_last: @request.remote_ip))
    end
  end
end
