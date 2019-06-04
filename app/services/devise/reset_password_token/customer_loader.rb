module Devise
  module ResetPasswordToken
    class CustomerLoader < ApplicationService
      def initialize(token)
        @token = token
      end

      def call
        encrypted_token = Devise.token_generator.digest(
          Customer,
          :reset_password_token,
          @token
        )

        Customer.find_or_initialize_with_error_by(
          :reset_password_token,
          encrypted_token
        )
      end
    end
  end
end
