module Forms
  module PaymentMethods
    class CreditCard
      include ActiveModel::Model

      DIGITS_LENGTH = 4
      MAX_HOLDER_NAME_LENGTH = 100

      attr_accessor :holder_name, :last_four_digits

      validates :holder_name, :last_four_digits, presence: true
      validates :holder_name, length: { maximum: MAX_HOLDER_NAME_LENGTH }
      validates :last_four_digits, numericality: true
      validates :last_four_digits, length: {
        is: DIGITS_LENGTH,
        message: I18n.t('errors.messages.withdrawal.last_four_digits')
      }
    end
  end
end
