# frozen_string_literal: true

module Customers
  module Summaries
    class BalanceUpdateWorker < ApplicationWorker
      SERVICE = Customers::Summaries::Updater
      def perform(day, balance_entry_id) # rubocop:disable Metrics/MethodLength
        balance_entry = BalanceEntry.find(balance_entry_id)

        attribute =
          case balance_entry.balance_entry_request&.entry_request&.kind
          when 'deposit'
            :"#{balance_entry.balance_entry_request.kind}_deposit_amount"
          when 'win'
            :"#{balance_entry.balance_entry_request.kind}_payout_amount"
          when 'withdraw'
            :withdraw_amount
          when 'bet'
            :"#{balance_entry.balance_entry_request.kind}_wager_amount"
          end

        return unless attribute

        Customers::Summaries::Updater.call(
          day,
          attribute => balance_entry.amount
        )
      end
    end
  end
end
