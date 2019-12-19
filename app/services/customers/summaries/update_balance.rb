# frozen_string_literal: true

module Customers
  module Summaries
    class UpdateBalance < ApplicationService
      def initialize(day:, entry:)
        @day = day
        @entry = entry
      end

      def call
        summary.lock!

        update_real_money_attribute
        update_bonus_attribute
      end

      private

      attr_reader :day, :entry

      def summary
        @summary ||= Customers::Summary.find_or_create_by(day: day)
      rescue ActiveRecord::RecordNotUnique
        @summary = Customers::Summary.all.reload.find_by!(day: day)
      end

      def update_real_money_attribute
        attribute_name = summary_attribute_name(:real_money)

        return unless attribute_name

        Customers::Summaries::Update
          .call(summary, attribute_name => real_money_amount)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
      def summary_attribute_name(balance_kind)
        case entry.kind
        when EntryKinds::DEPOSIT
          :"#{balance_kind}_deposit_amount"
        when EntryKinds::BONUS_CHANGE
          :bonus_deposit_amount
        when EntryKinds::WIN
          :"#{balance_kind}_payout_amount"
        when EntryKinds::WITHDRAW
          :withdraw_amount
        when EntryKinds::BET
          :"#{balance_kind}_wager_amount"
        when EntryKinds::EVERY_MATRIX_WAGER
          :"casino_#{balance_kind}_wager_amount"
        when EntryKinds::EVERY_MATRIX_RESULT
          :"casino_#{balance_kind}_payout_amount"
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

      def real_money_amount
        entry.base_currency_real_money_amount
      end

      def update_bonus_attribute
        attribute_name = summary_attribute_name(:bonus)

        return unless attribute_name

        Customers::Summaries::Update
          .call(summary, attribute_name => bonus_amount)
      end

      def bonus_amount
        entry.base_currency_bonus_amount
      end
    end
  end
end
