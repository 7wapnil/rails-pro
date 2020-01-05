# frozen_string_literal: true

module Customers
  module Statistics
    # rubocop:disable Metrics/ClassLength
    class Calculator < ApplicationService
      BATCH_SIZE = 200

      def initialize(customer:)
        @customer = customer
      end

      def call
        calculate_stats
        stats
      end

      private

      attr_reader :customer

      def calculate_stats
        stats.update(**explicit_attributes, **calculated_attributes)
      end

      def stats
        @stats ||= Customers::Statistic
                   .find_or_initialize_by(customer: customer)
      end

      def explicit_attributes
        {
          total_bonus_awarded: total_bonus_awarded,
          total_pending_bet_sum: total_pending_bet_sum,
          updated_at: Time.zone.now,
          last_updated_at: stats.updated_at
        }
      end

      def calculated_attributes
        {
          deposit_count: successful_deposits.count,
          deposit_value: deposit_value,
          withdrawal_count: successful_withdrawals.count,
          withdrawal_value: withdrawal_value,
          total_bonus_completed: total_bonus_completed,
          **BetsCalculator.call(customer),
          **CasinoCalculator.call(customer)
        }.map { |attribute, value| sum_up_attribute(attribute, value) }.to_h
      end

      def successful_deposits
        @successful_deposits ||= entries.deposit
      end

      def entries
        @entries ||= customer.entries
                             .joins(:currency)
                             .where(updated_at_clause('entries'))
      end

      def updated_at_clause(table_name)
        return 'true' if stats.new_record?

        "#{table_name}.updated_at >= '#{stats.updated_at.to_s(:db)}'"
      end

      def deposit_value
        successful_deposits
          .find_each(batch_size: BATCH_SIZE)
          .sum { |entry| convert_money(entry, :real_money_amount) }
      end

      def convert_money(record, attribute = :amount)
        money_converter.call(
          record.public_send(attribute),
          record.currency,
          primary_currency
        )
      end

      def money_converter
        @money_converter ||= ::Exchanger::Converter
      end

      def primary_currency
        @primary_currency ||= Currency.primary
      end

      def successful_withdrawals
        @successful_withdrawals ||=
          entries
          .includes(:withdrawal)
          .withdraw
          .where(customer_transactions: { status: Withdrawal::SUCCEEDED })
      end

      def withdrawal_value
        successful_withdrawals
          .find_each(batch_size: BATCH_SIZE)
          .sum { |entry| convert_money(entry, :real_money_amount) }
          .abs
      end

      def total_bonus_awarded
        customer
          .customer_bonuses
          .joins(:entry)
          .sum do |customer_bonus|
            convert_money(customer_bonus.entry, :bonus_amount)
          end
      end

      def total_bonus_completed
        entries.bonus_conversion
               .sum { |entry| convert_money(entry, :real_money_amount) }
      end

      def total_pending_bet_sum
        customer.bets
                .joins(:currency)
                .pending
                .or(customer.bets.joins(:currency).initial)
                .includes(:currency)
                .find_each(batch_size: BATCH_SIZE)
                .sum { |bet| convert_money(bet) }
      end

      def sum_up_attribute(attribute, value)
        [attribute, stats.send(attribute) + value]
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
