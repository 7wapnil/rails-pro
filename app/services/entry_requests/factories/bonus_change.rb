# frozen_string_literal: true

module EntryRequests
  module Factories
    class BonusChange < ApplicationService
      delegate :wallet, to: :customer_bonus

      def initialize(customer_bonus:, amount:, **params)
        @customer_bonus = customer_bonus
        @amount = amount
        @params = params
        @initiator = params[:initiator]
        @kind = params[:kind] || EntryRequest::BONUS_CHANGE
      end

      def call
        create_entry_request!
        validate_entry_request!

        entry_request
      end

      private

      attr_reader :customer_bonus, :amount, :params, :initiator, :kind
      attr_reader :entry_request

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        {
          amount: amount,
          bonus_amount: amount,
          mode: EntryRequest::INTERNAL,
          kind: kind,
          initiator: initiator,
          comment: comment,
          origin: customer_bonus,
          currency: wallet.currency,
          customer: wallet.customer,
          **bonus_track_attributes
        }
      end

      def bonus_track_attributes
        params.slice(:converted_bonus_amount, :confiscated_bonus_amount)
              .compact
      end

      def comment
        "Bonus transaction: #{amount} #{wallet.currency} " \
        "for #{wallet.customer}#{initiator_comment_suffix}."
      end

      def initiator_comment_suffix
        " by #{initiator}" if initiator
      end

      def validate_entry_request!
        check_bonus_expiration!
      end

      def check_bonus_expiration!
        return true if entry_request.amount.negative?
        return true unless customer_bonus.expired?

        entry_request.register_failure!(
          I18n.t('internal.errors.messages.entry_requests.bonus_expired')
        )
      end
    end
  end
end
