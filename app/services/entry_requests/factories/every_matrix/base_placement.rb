# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class BasePlacement < ApplicationService
        def initialize(transaction:, initiator: nil)
          @transaction = transaction
          @passed_initiator = initiator
        end

        def call
          create_entry_request!
          request_balance_update!

          entry_request
        end

        private

        attr_reader :transaction, :entry_request, :passed_initiator

        def create_entry_request!
          @entry_request = EntryRequest.create!(entry_request_attributes)
        end

        def entry_request_attributes
          transaction_attributes.merge(
            initiator: initiator,
            kind: entry_request_kind,
            mode: EntryRequest::INTERNAL
          )
        end

        def transaction_attributes
          {
            amount:      transaction.amount,
            currency:    transaction.currency,
            customer:    transaction.customer,
            origin:      transaction,
            external_id: transaction.transaction_id
          }
        end

        def initiator
          passed_initiator || transaction.customer
        end

        def request_balance_update!
          entry_request.update!(amount_calculations)
        end

        def amount_calculations
          balance_calculations_service.call(transaction: transaction)
        end

        def entry_request_kind
          error_msg = "#{__method__} needs to be implemented in #{self.class}"

          raise NotImplementedError, error_msg
        end

        def balance_calculations_service
          error_msg = "#{__method__} needs to be implemented in #{self.class}"

          raise NotImplementedError, error_msg
        end
      end
    end
  end
end
