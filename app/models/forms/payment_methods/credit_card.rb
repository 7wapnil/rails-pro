module Forms
  module PaymentMethods
    class CreditCard
      include ActiveModel::Model

      attr_accessor :holder_name, :last_four_digits

      validates :holder_name, :last_four_digits, presence: true
      validates :holder_name, length: { maximum: 100 }
      validates :last_four_digits, numericality: true
      validates :last_four_digits, length: { is: 4 }
    end
  end
end
