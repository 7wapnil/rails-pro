# frozen_string_literal: true

module Payments
  module Withdrawals
    module Customers
      # rubocop:disable Metrics/ClassLength
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
        validate :validate_balances, if: :wallet
        validate :validate_amount
        validate :validate_currency_rule

        delegate :real_money_balance, to: :wallet, allow_nil: true

        def validate_payment_details
          return if ::Payments::Withdraw::PAYMENT_METHODS
                    .exclude?(payment_method)

          form = payment_method_form_class.new(
            wallet: wallet,
            customer: customer,
            payment_method: payment_method,
            **payment_details.symbolize_keys
          )

          return if form.valid?

          form.errors.each { |attr, error| errors.add(attr, error) }
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        def payment_method_form_class
          case payment_method
          when CREDIT_CARD
            Payments::Withdrawals::Customers::Methods::CreditCardForm
          when NETELLER
            Payments::Withdrawals::Customers::Methods::NetellerForm
          when SKRILL
            Payments::Withdrawals::Customers::Methods::SkrillForm
          when ECO_PAYZ
            Payments::Withdrawals::Customers::Methods::EcoPayzForm
          when IDEBIT
            Payments::Withdrawals::Customers::Methods::IdebitForm
          when BITCOIN
            Payments::Withdrawals::Customers::Methods::BitcoinForm
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

        def validate_no_pending_bets_with_bonus
          return if !customer || no_pending_bets_with_bonus?

          errors.add(
            :base,
            I18n.t('errors.messages.withdrawal.pending_bets_with_bonus')
          )
        end

        def no_pending_bets_with_bonus?
          customer
            .bets
            .pending
            .joins(:entry_requests)
            .where.not(entry_requests: { bonus_amount: 0 })
            .none?
        end

        def validate_balances
          return if positive_balances?

          errors.add(
            :base,
            I18n.t('errors.messages.withdrawal.negative_balance')
          )
        end

        def validate_amount
          return unless amount && real_money_balance
          return if amount <= real_money_balance

          errors.add(
            :base,
            I18n.t('errors.messages.withdrawal.not_enough_money')
          )
        end

        def validate_currency_rule
          return true unless rule
          return amount_greater_than_allowed! if amount > rule.min_amount.abs

          amount_less_than_allowed! if -amount > rule.max_amount
        end

        def positive_balances?
          wallet
            .slice(:real_money_balance, :bonus_balance)
            .all? { |_, balance| balance >= 0 }
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
      # rubocop:enable Metrics/ClassLength
    end
  end
end
