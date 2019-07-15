# frozen_string_literal: true

module Payments
  module Withdrawals
    class CreateForm
      include ActiveModel::Model
      include ::Payments::Methods

      MIN_AMOUNT = 0
      MAX_AMOUNT = 10_000
      AMOUNT_FORMAT_REGEX = /\A\d{1,12}(\.\d{0,2})?\z/

      attr_accessor :amount,
                    :wallet,
                    :payment_method,
                    :payment_details,
                    :customer

      validates :amount,
                :wallet,
                :payment_method,
                :customer, presence: true
      validates :amount,
                numericality: { greater_than: MIN_AMOUNT },
                format: { with: AMOUNT_FORMAT_REGEX }
      validates :payment_method,
                inclusion: {
                  in: ::Payments::Withdraw::PAYMENT_METHODS,
                  message: I18n.t(
                    'errors.messages.withdrawal.method_not_supported'
                  )
                }

      validate :validate_payment_details
      validate :validate_no_pending_bets_with_bonus
      validate :validate_amount
      validate :validate_currency_rule

      delegate :real_money_balance, to: :wallet, allow_nil: true

      def validate_payment_details
        return if ::Payments::Withdraw::PAYMENT_METHODS.exclude?(payment_method)

        form = payment_method_form_class.new(
          wallet: wallet,
          customer: customer,
          payment_method: payment_method,
          **payment_details.symbolize_keys
        )

        return if form.valid?

        form.errors.each { |attr, error| errors.add(attr, error) }
      end

      def payment_method_form_class
        case payment_method
        when CREDIT_CARD then Payments::Withdrawals::Methods::CreditCardForm
        when NETELLER then Payments::Withdrawals::Methods::NetellerForm
        when SKRILL then Payments::Withdrawals::Methods::SkrillForm
        when BITCOIN then Payments::Withdrawals::Methods::BitcoinForm
        end
      end

      def validate_no_pending_bets_with_bonus
        return if !customer || no_pending_bets_with_bonus?

        errors.add(:base,
                   I18n.t('errors.messages.withdrawal.pending_bets_with_bonus'))
      end

      def no_pending_bets_with_bonus?
        customer
          .bets
          .pending
          .joins(entry_requests: :bonus_balance_entry_request)
          .none?
      end

      def validate_amount
        return unless amount
        return if real_money_balance && amount <= real_money_balance.amount

        errors.add(:base, I18n.t('errors.messages.withdrawal.not_enough_money'))
      end

      def validate_currency_rule
        return true unless rule
        return amount_greater_than_allowed! if amount > rule.min_amount.abs

        amount_less_than_allowed! if -amount > rule.max_amount
      end

      def rule
        @rule ||= EntryCurrencyRule.find_by(currency: currency,
                                            kind: EntryKinds::WITHDRAW)
      end

      def currency
        @currency ||= wallet&.currency
      end

      def amount_less_than_allowed!
        errors.add(:amount,
                   I18n.t('errors.messages.minimum_withdrawal_amount_reached',
                          min_amount: rule.max_amount.abs,
                          currency: currency.to_s))
      end

      def amount_greater_than_allowed!
        errors.add(:amount,
                   I18n.t('errors.messages.maximum_withdrawal_amount_reached',
                          max_amount: rule.min_amount.abs,
                          currency: currency.to_s))
      end
    end
  end
end
