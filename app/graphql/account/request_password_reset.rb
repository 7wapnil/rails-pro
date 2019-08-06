# frozen_string_literal: true

module Account
  class RequestPasswordReset < ::Base::Resolver
    argument :email, !types.String

    type types.Boolean

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      customer = Customer.find_by!(email: args[:email])
      Account::SendPasswordResetService.call(customer)

      true
    rescue ActiveRecord::RecordNotFound
      raise ::ResolvingError,
            email: I18n.t('account.request_password_reset.not_found_error')
    rescue StandardError
      raise I18n.t('account.request_password_reset.technical_error')
    end
  end
end
