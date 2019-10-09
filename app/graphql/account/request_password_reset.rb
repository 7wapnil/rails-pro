# frozen_string_literal: true

module Account
  class RequestPasswordReset < ::Base::Resolver
    argument :email, !types.String
    argument :captcha, !types.String

    type types.Boolean

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      service = Account::SendPasswordResetService.new(email: args[:email],
                                                      captcha: args[:captcha])

      return service.captcha_invalid! if service.captcha_invalid?

      raise ActiveRecord::RecordNotFound unless service.customer

      service.call

      true
    rescue ActiveRecord::RecordNotFound
      true
    rescue StandardError
      raise I18n.t('account.request_password_reset.technical_error')
    end
  end
end
