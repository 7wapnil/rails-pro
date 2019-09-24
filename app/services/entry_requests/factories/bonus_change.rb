# frozen_string_literal: true

module EntryRequests
  module Factories
    class BonusChange < ApplicationService
      delegate :wallet, to: :customer_bonus

      def initialize(customer_bonus:, amount:, **params)
        @customer_bonus = customer_bonus
        @amount = amount
        @initiator = params[:initiator]
      end

      def call
        create_entry_request!
        request_balance_update!
        validate_entry_request!

        entry_request
      end

      private

      attr_reader :customer_bonus, :amount, :initiator, :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          amount: amount,
          mode: EntryRequest::INTERNAL,
          kind: EntryRequest::BONUS_CHANGE,
          initiator: initiator,
          comment: comment,
          origin: customer_bonus,
          currency: wallet.currency,
          customer: wallet.customer
        }
      end

      def comment
        "Bonus transaction: #{amount} #{wallet.currency} " \
        "for #{wallet.customer}#{initiator_comment_suffix}."
      end

      def initiator_comment_suffix
        " by #{initiator}" if initiator
      end

      def request_balance_update!
        entry_request.update(bonus_amount: amount)
      end

      def validate_entry_request!
        check_bonus_expiration!
      end

      def check_bonus_expiration!
        return true if entry_request.amount.negative?
        return true unless customer_bonus.expired?

        entry_request.register_failure!(
          I18n.t('errors.messages.entry_requests.bonus_expired')
        )
      end
    end
  end
end
