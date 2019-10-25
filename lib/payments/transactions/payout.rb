# frozen_string_literal: true

module Payments
  module Transactions
    class Payout < ::Payments::Transactions::Base
      attr_accessor :details, :withdrawal

      validates :withdrawal, presence: true
      validates :details, presence: true
      validate :possible_withdrawal, if: :withdrawal

      def possible_withdrawal
        return if balance_reduced?

        errors.add(
          :cashier,
          I18n.t('errors.messages.withdrawal.invalid_withdrawal')
        )
      end

      def balance_reduced?
        withdrawal
          .entry_requests
          .joins(:entry)
          .where(kind: EntryRequest::WITHDRAW, status: EntryRequest::SUCCEEDED)
          .any?
      end
    end
  end
end
