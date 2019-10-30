module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      auth_params = args[:input]
      customer = Customer.find_for_authentication(login: auth_params[:login])
      service = Account::SignInService.new(
        customer: customer,
        params: auth_params,
        request: @request
      )

      service.validate_login!

      customer.update_tracked_fields!(@request)
      Customers::VisitLogService.call(customer, @request, sign_in: true)
      customer.valid_login_attempt!

      @current_customer = customer

      service.login_response
    end
  end
end
