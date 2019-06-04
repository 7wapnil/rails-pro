module Account
  module VerifyPasswordToken
    class Response
      attr_reader :success, :message

      def initialize(success:, message:)
        @success = success
        @message = message
      end

      def self.valid
        new(success: true,
            message: I18n.t('messages.reset_password_token.valid'))
      end

      def self.invalid
        new(success: false,
            message: I18n.t('messages.reset_password_token.invalid'))
      end

      def self.expired
        new(success: false,
            message: I18n.t('messages.reset_password_token.expired'))
      end
    end
  end
end
