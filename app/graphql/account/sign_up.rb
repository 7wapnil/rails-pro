# frozen_string_literal: true

module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    argument :userData, Account::UserDataInput, default_value: nil

    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      input = args[:input]
      return unless input

      @customer = ::Customers::RegistrationService.call(input.to_h, @request)
      save_customer_data(args)
      token = JwtService.encode(
        id: customer.id,
        username: customer.username,
        email: customer.email,
        exp: ENV.fetch('TOKEN_EXPIRATION', 30).to_f.days.from_now.to_i
      )
      OpenStruct.new(user: customer, token: token)
    end

    private

    attr_reader :customer

    def save_customer_data(args)
      customer_data_attrs = args['userData']&.to_h
      return if customer_data_attrs.blank?

      customer_data = customer_data_attrs.transform_keys! do |key|
        key.to_s.underscore.to_sym
      end
      CustomerData.create(customer_data.merge(customer: customer,
                                              ip_last: @request.remote_ip))
    end
  end
end
