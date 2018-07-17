module Account
  class SignUp < ::Base::Resolver
    argument :input, !Account::RegisterInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      input = args[:input]
      return unless input

      customer = Customer.create!(input.to_h)
      customer.update_tracked_fields!(@request)
      @current_customer = customer
      log_record_event :customer_signed_up, customer
      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
