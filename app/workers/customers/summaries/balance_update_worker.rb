# frozen_string_literal: true

module Customers
  module Summaries
    class BalanceUpdateWorker < ApplicationWorker
      def perform(day, entry_id)
        @day = day
        @entry = Entry.find(entry_id)

        Customers::Summaries::Updater.call(
          day,
          summary_field(:real_money) => entry.base_currency_real_money_amount
        )
        Customers::Summaries::Updater.call(
          day,
          summary_field(:bonus) => entry.base_currency_bonus_amount
        )
      rescue StandardError => error
        log_error(error)
        nil
      end

      private

      attr_reader :day, :entry

      # rubocop:disable Metrics/CyclomaticComplexity
      def summary_field(money_type)
        case entry.kind
        when EntryKinds::DEPOSIT
          :"#{money_type}_deposit_amount"
        when EntryKinds::BONUS_CHANGE
          :bonus_deposit_amount if entry.amount.positive?
        when EntryKinds::WIN
          :"#{money_type}_payout_amount"
        when EntryKinds::WITHDRAW
          :withdraw_amount
        when EntryKinds::BET
          :"#{money_type}_wager_amount"
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def log_error(error)
        Rails.logger.error(
          message: 'Error on customer summary report calculation',
          day: day,
          entry_id: entry&.id,
          error_object: error
        )
      end
    end
  end
end
