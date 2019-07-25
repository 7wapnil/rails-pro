# frozen_string_literal: true

module Payments
  module Deposits
    class CreateForm
      include ActiveModel::Model
      include ::Payments::Methods

      attr_accessor :amount, :wallet, :bonus, :payment_method

      validates :amount, :wallet, presence: true
      validates :payment_method,
                inclusion: {
                  in: ::Payments::Deposit::PAYMENT_METHODS,
                  message: I18n.t(
                    'errors.messages.deposit.method_not_supported'
                  )
                }

      validate :validate_currency_rule
      validate :validate_bonus_expiration

      def validate_bonus_expiration
        return true unless bonus&.expired?

        raise CustomerBonuses::ActivationError,
              I18n.t('errors.messages.entry_requests.bonus_expired')
      end

      def validate_currency_rule
        return true unless rule
        return amount_less_than_null! unless amount.positive?
        return amount_less_than_allowed! if amount < rule.min_amount.abs

        amount_greater_than_allowed! if amount > rule.max_amount
      end

      def rule
        @rule ||= EntryCurrencyRule.find_by(currency: currency,
                                            kind: EntryKinds::DEPOSIT)
      end

      def currency
        @currency ||= wallet&.currency
      end

      def amount_less_than_null!
        errors.add(
          :amount,
          I18n.t('errors.messages.amount_less_than_allowed',
                 min_amount: 0,
                 currency: currency.to_s)
        )
      end

      def amount_less_than_allowed!
        errors.add(
          :amount,
          I18n.t('errors.messages.amount_less_than_allowed',
                 min_amount: rule.min_amount,
                 currency: currency.to_s)
        )
      end

      def amount_greater_than_allowed!
        errors.add(
          :amount,
          I18n.t('errors.messages.amount_greater_than_allowed',
                 max_amount: rule.max_amount,
                 currency: currency.to_s)
        )
      end
    end
  end
end
