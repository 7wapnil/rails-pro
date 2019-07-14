# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class WithdrawalMethodForm
        include ActiveModel::Model

        attr_accessor :wallet, :customer, :payment_method

        validate :payment_consistency,
                 if: :wallet,
                 unless: -> { wallet.currency.crypto? }

        def payment_consistency
          return if payment_exist?

          errors.add(:base, consistency_error_message)
        end

        def payment_exist?
          customer.entry_requests
                  .deposit
                  .succeeded
                  .joins(:deposit, :entry)
                  .where(query_string, send(identifier).to_s)
                  .present?
        end

        def query_string
          "customer_transactions.details ->> '#{identifier}' = ?"
        end

        def identifier
          raise NotImplementedError
        end

        def consistency_error_message
          raise NotImplementedError
        end
      end
    end
  end
end
