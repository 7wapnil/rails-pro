# frozen_string_literal: true

module Customers
  module Summaries
    class BalanceUpdateWorker < ApplicationWorker
      def perform(day, balance_entry_id)
        @balance_entry = BalanceEntry.find(balance_entry_id)
        attribute = summary_attribute

        return unless attribute

        Customers::Summaries::Updater.call(
          day,
          attribute => balance_entry.amount
        )
      end

      private

      attr_reader :balance_entry

      def summary_attribute # rubocop:disable Metrics/CyclomaticComplexity
        case entry_kind
        when 'deposit'
          :"#{entry_request_kind}_deposit_amount"
        when 'bonus_change'
          :bonus_deposit_amount if balance_entry.amount.positive?
        when 'win'
          :"#{entry_request_kind}_payout_amount"
        when 'withdraw'
          :withdraw_amount
        when 'bet'
          :"#{entry_request_kind}_wager_amount"
        end
      end

      def entry_kind
        balance_entry.balance_entry_request&.entry_request&.kind
      end

      def entry_request_kind
        balance_entry.balance_entry_request.kind
      end
    end
  end
end
