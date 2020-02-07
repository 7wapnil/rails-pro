# frozen_string_literal: true

module EntryRequests
  module Factories
    class Confiscation < ApplicationService
      def initialize(transaction:)
        @transaction = transaction
        @amount = -transaction.amount.abs
      end

      def call
        create_entry_request!
        create_confiscation!
        validate_business_rules!

        entry_request
      end

      private

      attr_reader :transaction, :amount, :entry_request, :confiscation

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          kind: EntryRequest::CONFISCATION,
          currency: transaction.currency,
          customer: transaction.customer,
          amount: amount,
          mode: EntryRequest::CASHIER,
          initiator: transaction.initiator,
          comment: transaction.comment,
          real_money_amount: amount
        )
      end

      def create_confiscation!
        @confiscation = ::Confiscation.create!(
          entry_request: entry_request,
          status: CustomerTransaction::PENDING
        )
      end

      def validate_business_rules!
        form = ::Payments::Confiscations::Backoffice::CreateForm.new(
          amount: transaction.amount.abs,
          wallet: transaction.wallet,
          payment_method: EntryRequest::CASHIER,
          initiator: transaction.initiator,
          customer: transaction.customer
        )
        form.validate!
      rescue ActiveModel::ValidationError => error
        fail_confiscation_request!(error)

        false
      end

      def fail_confiscation_request!(error)
        entry_request.register_failure!(error.message)
        confiscation.failed!
      end
    end
  end
end
