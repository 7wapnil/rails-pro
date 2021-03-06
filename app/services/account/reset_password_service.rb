module Account
  class ResetPasswordService < ApplicationService
    attr_reader :customer, :token, :password, :confirmation

    def initialize(token, password, confirmation)
      @token = token
      @password = password
      @confirmation = confirmation
      @customer = Devise::ResetPasswordToken::CustomerLoader.call(token)
    end

    def call
      raise_gql('empty_token') unless token
      raise_gql('token_not_found') unless customer.persisted?
      raise_gql('token_expired') unless customer.reset_password_period_valid?
      raise_gql('confirmation_mismatch') unless password == confirmation

      customer.reset_password(password, confirmation)

      true
    end

    private

    def raise_gql(name)
      raise GraphQL::ExecutionError,
            I18n.t("internal.errors.messages.reset_password_#{name}")
    end
  end
end
