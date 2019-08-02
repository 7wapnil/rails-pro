# frozen_string_literal: true

module EntryRequests
  module Factories
    # rubocop:disable Metrics/ClassLength
    class Deposit < ApplicationService
      delegate :wallet, to: :transaction
      delegate :currency, to: :wallet

      def initialize(transaction:, customer_bonus: nil)
        @transaction = transaction
        @customer_bonus = customer_bonus
      end

      def call
        create_entry_request!
        create_balance_request!
        create_deposit!
        validate_entry_request!

        entry_request
      end

      private

      attr_reader :transaction, :customer_bonus, :entry_request, :deposit

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          status: EntryRequest::INITIAL,
          amount: amount_value,
          mode: transaction.method,
          kind: EntryRequest::DEPOSIT,
          initiator: initiator,
          comment: comment,
          currency: transaction.wallet.currency,
          customer: transaction.customer,
          external_id: transaction.external_id
        }
      end

      def amount_value
        @amount_value ||= calculations.values.sum
      end

      def calculations
        @calculations ||= BalanceCalculations::Deposit.call(
          transaction.amount,
          currency,
          customer_bonus&.original_bonus,
          no_bonus: bonus_not_applied?
        )
      end

      def bonus_not_applied?
        customer_bonus&.active?.present?
      end

      def initiator
        @initiator ||= transaction.initiator || transaction.customer
      end

      def comment
        transaction.comment.presence || default_comment
      end

      def default_comment
        "Deposit #{calculations[:real_money]} #{transaction.currency_code}" \
        " real money and #{calculations[:bonus] || 0} " \
        "#{transaction.currency_code} bonus money " \
        "(#{transaction.customer&.pending_bonus&.code || 'no'} bonus code) " \
        "for #{transaction.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{transaction.initiator}" if transaction.initiator
      end

      def create_balance_request!
        ::BalanceRequestBuilders::Deposit.call(entry_request, calculations)
      end

      def create_deposit!
        @deposit = ::Deposit.create!(
          status: ::CustomerTransaction::PENDING,
          entry_request: entry_request,
          customer_bonus: customer_bonus
        )
      end

      def validate_entry_request!
        validate_customer_rules! && validate_business_rules!
      end

      def validate_business_rules!
        form = business_rules_form.new(
          amount: transaction.amount,
          wallet: transaction.wallet,
          payment_method: transaction.method,
          bonus: customer_bonus
        )
        form.validate!
      rescue ActiveModel::ValidationError
        validation_failed(form)

        false
      end

      def business_rules_form
        return customers_create_form if validate_customer_rules?

        backoffice_create_form
      end

      def customers_create_form
        ::Payments::Deposits::Customers::CreateForm
      end

      def backoffice_create_form
        ::Payments::Deposits::Backoffice::CreateForm
      end

      def validate_customer_rules?
        transaction.initiator.is_a?(Customer)
      end

      def validate_customer_rules!
        return true if initiator.is_a?(User)

        form = ::Payments::Deposits::Customers::RulesForm.new(
          customer: transaction.customer,
          amount: transaction.amount,
          wallet: transaction.wallet
        )
        form.validate!
      rescue ActiveModel::ValidationError
        validation_failed(form)

        false
      end

      def validation_failed(form)
        attribute, message = form.errors.first

        entry_request.register_failure!(message, attribute)
        fail_related_entities!
      end

      def fail_related_entities!
        customer_bonus&.fail!
        deposit&.failed!
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
