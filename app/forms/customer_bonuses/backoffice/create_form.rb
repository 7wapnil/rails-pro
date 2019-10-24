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
      validate :maximum_bonus_amount

      def submit!
        validate!
        activation_service.call
      end

      private

      def maximum_bonus_amount
        return unless amount && bonus
        return if amount.to_f <= max_deposit_bonus

        errors.add(:bonus, "max deposit bonus: #{max_deposit_bonus}")
      end

      def activation_service
        @activation_service ||= Bonuses::ActivationService.new(
          wallet: wallet,
          bonus: bonus,
          amount: amount,
          initiator: initiator
        )
      end

      def max_deposit_bonus
        @max_deposit_bonus ||= Exchanger::Converter.call(
          bonus.max_deposit_match,
          Currency.primary,
          wallet.currency
        )
      end
    end
  end
end
