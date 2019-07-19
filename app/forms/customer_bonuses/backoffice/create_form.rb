module CustomerBonuses
  module Backoffice
    class CreateForm
      include ActiveModel::Model

      attr_accessor :bonus,
                    :wallet,
                    :amount,
                    :initiator

      validates :bonus,
                :wallet,
                :amount,
                :initiator,
                presence: true

      validates :amount, numericality: { greater_than: 0 }

      def submit!
        validate!
        activation_service.call
      end

      private

      def activation_service
        @activation_service ||= Bonuses::ActivationService.new(
          wallet: wallet,
          bonus: bonus,
          amount: amount,
          initiator: initiator
        )
      end
    end
  end
end
