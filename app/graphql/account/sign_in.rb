module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args) # rubocop:disable Metrics/MethodLength
      auth_params = args[:input]
      customer = Customer.find_for_authentication(login: auth_params[:login])
      service = Account::SignInService.new(
        customer: customer,
        params: auth_params,
        request: @request
      )

      return service.invalid_captcha! if service.captcha_invalid?
      return service.reset_password!  if service.imported_customer_first_login?
      return service.invalid_login!   if service.invalid_password?

      customer.update_tracked_fields!(@request)
      customer.valid_login_attempt!

      @current_customer = customer

      service.login_response
    end
  end
end
