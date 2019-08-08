# frozen_string_literal: true

module Account
  class Impersonate < ::Base::Resolver
    type Account::AccountType

    argument :token, !types.String

    def auth_protected?
      false
    end

    def resolve(*, args)
      ::Account::ImpersonateResolver.call(
        token: args[:token],
        ip_address: @request.remote_ip
      )
    rescue StandardError
      raise ActiveRecord::RecordNotFound, I18n.t('account.impersonate.failure')
    end
  end
end
