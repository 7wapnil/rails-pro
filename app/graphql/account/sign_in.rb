module Account
  class SignIn < ::Base::Resolver
    argument :input, !Account::AuthInput
    type Account::AccountType

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      login = args[:input][:login]
      customer = Customer.find_for_authentication(login: login)

      if customer&.valid_password?(args[:input][:password])
        customer.update_tracked_fields!(@request)
        @current_customer = customer
        return account_locked_response(customer) if customer.locked

        customer.log_event :customer_signed_in
        response(customer)
      else
        GraphQL::ExecutionError.new(
          I18n.t('errors.messages.wrong_login_credentials')
        )
      end
    end

    private

    def account_locked_response(customer)
      customer.log_event :locked_customer_sign_in_attempt
      GraphQL::ExecutionError.new(
        account_locked_message(customer)
      )
    end

    def account_locked_message(customer)
      account_lock_time = customer.locked_until
      if account_lock_time.nil?
        return I18n.t('errors.messages.account_locked.default')
      end

      I18n.t(
        'errors.messages.account_locked.default',
        additional_info: I18n.t(
          'errors.messages.account_locked.additional_info.until',
          until_date: customer.locked_until.strftime(
            I18n.t('date.formats.default')
          )
        )
      )
    end

    def response(customer)
      OpenStruct.new(user: customer,
                     token: JwtService.encode(id: customer.id,
                                              username: customer.username,
                                              email: customer.email))
    end
  end
end
