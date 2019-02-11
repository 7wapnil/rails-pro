module EntryRequests
  module Factories
    class Deposit < ApplicationService
      delegate :expired?, to: :customer_bonus, allow_nil: true, prefix: true

      def initialize(wallet:, amount:, **attributes)
        @wallet = wallet
        @amount = amount
        @mode = attributes[:mode] || EntryRequest::CASHIER
        @passed_initiator = attributes[:initiator]
        @passed_comment = attributes[:comment]
        @customer_bonus = wallet.customer.customer_bonus
      end

      def call
        create_entry_request!
        validate_entry_request!
        create_balance_request!

        entry_request
      end

      private

      attr_reader :wallet, :amount, :passed_initiator, :mode,
                  :passed_comment, :customer_bonus, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        wallet_attributes.merge(
          amount: amount_value,
          mode: mode,
          kind: EntryRequest::DEPOSIT,
          initiator: initiator,
          comment: comment
        )
      end

      def wallet_attributes
        {
          origin:   wallet,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def amount_value
        @amount_value ||= calculations.values.sum
      end

      def calculations
        @calculations ||=
          BalanceCalculations::Deposit
          .call(customer_bonus, amount)
          .tap { |amounts| amounts[:bonus] = 0 unless eligible_for_bonus? }
      end

      def eligible_for_bonus?
        customer_bonus.present? &&
          !customer_bonus.activated? &&
          customer_bonus.min_deposit &&
          customer_bonus.applied? &&
          amount >= customer_bonus.min_deposit
      end

      def initiator
        @initiator ||= passed_initiator || wallet.customer
      end

      def comment
        passed_comment.presence || default_comment
      end

      def default_comment
        "Deposit #{amount_value} #{wallet.currency} " \
        "for #{wallet.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{passed_initiator}" if passed_initiator
      end

      def validate_entry_request!
        check_deposit_limit! && check_bonus_expiration!
      end

      def check_deposit_limit!
        # TODO : implement validation logic
        deposit_limit = DepositLimit.find_by(customer: wallet.customer,
                                             currency: wallet.currency)

        return true unless deposit_limit

        entry_request
          .register_failure!(I18n.t('errors.messages.deposit_limit_present'))
      end

      def check_bonus_expiration!
        return true unless customer_bonus_expired?

        customer_bonus.close!(BonusExpiration::Expired,
                              reason: :expired_by_date)
        entry_request
          .register_failure!(I18n.t('errors.messages.bonus_expired'))
      end

      def create_balance_request!
        BalanceRequestBuilders::Deposit.call(entry_request, calculations)
      end
    end
  end
end
