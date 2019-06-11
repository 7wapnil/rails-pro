# frozen_string_literal: true

module EntryRequests
  module Factories
    # rubocop:disable Metrics/ClassLength
    class Deposit < ApplicationService
      def initialize(wallet:, amount:, customer_bonus: nil, **attributes)
        @wallet = wallet
        @amount = amount
        @customer_bonus = customer_bonus
        @mode = attributes[:mode]
        @passed_initiator = attributes[:initiator]
        @passed_comment = attributes[:comment]
      end

      def call
        create_entry_request!
        create_balance_request!
        create_deposit!
        validate_entry_request!

        entry_request
      end

      private

      attr_reader :wallet, :amount, :customer_bonus, :passed_initiator,
                  :mode, :passed_comment, :entry_request

      delegate :currency, to: :wallet, prefix: true

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          status: EntryRequest::INITIAL,
          amount: amount_value,
          mode: mode,
          kind: EntryRequest::DEPOSIT,
          initiator: initiator,
          comment: comment,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def amount_value
        @amount_value ||= calculations.values.sum
      end

      def calculations
        @calculations ||= BalanceCalculations::Deposit.call(
          amount,
          customer_bonus&.original_bonus,
          no_bonus: bonus_not_applied?
        )
      end

      def bonus_not_applied?
        customer_bonus&.active?.present?
      end

      def initiator
        @initiator ||= passed_initiator || wallet.customer
      end

      def comment
        passed_comment.presence || default_comment
      end

      def default_comment
        "Deposit #{calculations[:real_money]} #{wallet.currency} real money " \
        "and #{calculations[:bonus] || 0} #{wallet.currency} bonus money " \
        "(#{wallet.customer&.pending_bonus&.code || 'no'} bonus code) " \
        "for #{wallet.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{passed_initiator}" if passed_initiator
      end

      def create_balance_request!
        BalanceRequestBuilders::Deposit.call(entry_request, calculations)
      end

      def create_deposit!
        ::Deposit.create!(
          entry_request: entry_request,
          customer_bonus: customer_bonus
        )
      end

      # TODO: extract to form object
      def validate_entry_request!
        check_currency_rule!
        check_bonus_expiration!
        perform_customer_validations! unless initiator.is_a?(User)

        true
      rescue *::Payments::Deposit::BUSINESS_ERRORS => error
        entry_request.register_failure!(error.message)
        customer_bonus&.fail!
      end

      def check_currency_rule!
        return true unless currency_rule
        return amount_greater_than_allowed! if amount > currency_rule.max_amount

        amount_less_than_allowed! if amount < currency_rule.min_amount
      end

      def currency_rule
        @currency_rule ||= EntryCurrencyRule.find_by(currency: wallet.currency,
                                                     kind: EntryKinds::DEPOSIT)
      end

      def amount_less_than_allowed!
        raise ::Deposits::CurrencyRuleError,
              I18n.t('errors.messages.amount_less_than_allowed',
                     min_amount: currency_rule.min_amount,
                     currency: wallet_currency.code)
      end

      def amount_greater_than_allowed!
        raise ::Deposits::CurrencyRuleError,
              I18n.t('errors.messages.amount_greater_than_allowed',
                     max_amount: currency_rule.max_amount,
                     currency: currency.code)
      end

      def check_bonus_expiration!
        return true unless customer_bonus&.expired?

        raise CustomerBonuses::ActivationError,
              I18n.t('errors.messages.entry_requests.bonus_expired')
      end

      def perform_customer_validations!
        verify_deposit_attempts!
        check_deposit_limit!
      end

      def check_deposit_limit!
        ::Deposits::DepositLimitCheckService
          .call(wallet.customer, amount, wallet.currency)
      end

      def verify_deposit_attempts!
        ::Deposits::VerifyDepositAttempt.call(wallet.customer)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
