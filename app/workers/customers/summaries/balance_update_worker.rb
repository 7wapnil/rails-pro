# frozen_string_literal: true

module Customers
  module Summaries
    class BalanceUpdateWorker < ApplicationWorker
      def perform(day, entry_id)
        @entry = Entry.find(entry_id)

        Customers::Summaries::Updater.call(
          day,
          summary_attribute(:real_money) =>
            entry.base_currency_real_money_amount
        )
        Customers::Summaries::Updater.call(
          day,
          summary_attribute(:bonus) => entry.base_currency_bonus_amount
        )
      end

      private

      attr_reader :entry

      # rubocop:disable Metrics/CyclomaticComplexity
      def summary_attribute(money_type)
        case entry.kind
        when 'deposit'
          :"#{money_type}_deposit_amount"
        when 'bonus_change'
          :bonus_deposit_amount if entry.amount.positive?
        when 'win'
          :"#{money_type}_payout_amount"
        when 'withdraw'
          :withdraw_amount
        when 'bet'
          :"#{money_type}_wager_amount"
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
