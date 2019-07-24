# frozen_string_literal: true

module EntryRequests
  module Factories
    class Withdrawal < ApplicationService
      def initialize(transaction:)
        @transaction = transaction
        @amount = -transaction.amount.abs
      end

      def call
        create_entry_request!
        create_balance_entry_request!
        create_withdrawal!
        validate_entry_request!

        entry_request
      end

      private

      attr_reader :transaction, :amount, :entry_request, :withdrawal

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          kind: EntryRequest::WITHDRAW,
          currency: transaction.currency,
          customer: transaction.customer,
          amount: amount,
          mode: transaction.method,
          initiator: initiator,
          comment: comment
        )
      end

      def initiator
        @initiator ||= transaction.initiator || transaction.customer
      end

      def comment
        transaction.comment.presence || default_comment
      end

      def default_comment
        "Withdrawal #{amount.abs} #{transaction.currency}" \
        " for #{transaction.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{transaction.initiator}" if transaction.initiator
      end

      def create_balance_entry_request!
        BalanceRequestBuilders::Withdrawal.call(entry_request,
                                                real_money: amount)
      end

      def create_withdrawal!
        @withdrawal = ::Withdrawal.create!(
          entry_request: entry_request,
          status: CustomerTransaction::PENDING,
          details: transaction.details
        )
      end

      def validate_entry_request!
        validate_customer_rules! && validate_business_rules!
      end

      def validate_business_rules!
        form = business_rules_validation_form.new(
          amount: transaction.amount.abs,
          wallet: transaction.wallet,
          payment_method: transaction.method,
          payment_details: transaction.details,
          customer: transaction.customer
        )
        form.validate!
      rescue ActiveModel::ValidationError
        validation_failed(form)

        false
      end

      def business_rules_validation_form
        return ::Payments::Withdrawals::CreateForm if validate_payment_details?

        ::Payments::Withdrawals::BackofficeCreateForm
      end

      def validation_failed(form)
        attribute, message = form.errors.first

        entry_request.register_failure!(message, attribute)
        withdrawal.failed!
      end

      def validate_customer_rules!
        return true unless validate_customer_rules?

        form = ::Payments::Withdrawals::CustomerRulesForm.new(
          password: transaction.password,
          customer: transaction.customer
        )
        form.validate!
      rescue ActiveModel::ValidationError
        validation_failed(form)

        false
      end

      def validate_customer_rules?
        transaction.initiator.is_a?(Customer)
      end

      alias_method :validate_payment_details?, :validate_customer_rules?
    end
  end
end
