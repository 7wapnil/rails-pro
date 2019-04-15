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
        stats.update(updated_at: Time.zone.now, **calculated_attributes)
      end

      def stats
        @stats ||= Customers::Statistic
                   .find_or_initialize_by(customer: customer)
      end

      # rubocop:disable Metrics/MethodLength
      def calculated_attributes
        {
          deposit_count: successful_deposits.count,
          deposit_value: deposit_value,
          withdrawal_count: successful_withdrawals.count,
          withdrawal_value: withdrawal_value,
          theoretical_bonus_cost: 0.0,
          potential_bonus_cost: 0.0,
          actual_bonus_cost: 0.0,
          prematch_bet_count: prematch_bets.count,
          prematch_wager: prematch_wager,
          prematch_payout: prematch_payout,
          live_bet_count: live_bets.count,
          live_sports_wager: live_sports_wager,
          live_sports_payout: live_sports_payout,
          total_pending_bet_sum: total_pending_bet_sum
        }.map { |attribute, value| sum_up_attribute(attribute, value) }.to_h
      end
      # rubocop:enable Metrics/MethodLength

      def sum_up_attribute(attribute, value)
        [attribute, stats.send(attribute) + value]
      end

      def deposit_value
        successful_deposits.find_each(batch_size: BATCH_SIZE)
                           .sum { |entry| convert_money(entry) }
      end

      def updated_at_clause(table_name)
        return 'true' if stats.new_record?

        "#{table_name}.updated_at >= '#{stats.updated_at.to_s(:db)}'"
      end

      def successful_deposits
        @successful_deposits ||= entries.deposit
      end

      def entries
        @entries ||= customer.entries
                             .joins(:currency)
                             .where(updated_at_clause('entries'))
      end

      def convert_money(record)
        money_converter.convert(record.amount, record.currency.code)
      end

      def money_converter
        @money_converter ||= MoneyConverter::Service.new
      end

      def withdrawal_value
        successful_withdrawals.find_each(batch_size: BATCH_SIZE)
                              .sum { |entry| convert_money(entry) }
                              .abs
      end

      def successful_withdrawals
        @successful_withdrawals ||=
          entries
          .includes(:withdrawal_request)
          .withdraw
          .where(origin_type: WithdrawalRequest.name,
                 withdrawal_requests: { status: WithdrawalRequest::APPROVED })
      end

      def prematch_wager
        prematch_bets.find_each(batch_size: BATCH_SIZE)
                     .sum { |bet| convert_money(bet) }
      end

      def prematch_bets
        @prematch_bets ||= settled_bets
                           .where('bets.created_at <= events.start_at')
      end

      def settled_bets
        @settled_bets ||= customer.bets
                                  .joins(:event, :currency)
                                  .settled
                                  .where(updated_at_clause('bets'))
      end

      def prematch_payout
        prematch_bets.won
                     .find_each(batch_size: BATCH_SIZE)
                     .sum { |bet| convert_money(bet) }
      end

      def live_sports_wager
        live_bets.find_each(batch_size: BATCH_SIZE)
                 .sum { |bet| convert_money(bet) }
      end

      def live_bets
        @live_bets ||= settled_bets.where('bets.created_at > events.start_at')
      end

      def live_sports_payout
        live_bets.won
                 .find_each(batch_size: BATCH_SIZE)
                 .sum { |bet| convert_money(bet) }
      end

      def total_pending_bet_sum
        customer.bets
                .joins(:currency)
                .pending
                .where(updated_at_clause('bets'))
                .find_each(batch_size: BATCH_SIZE)
                .sum { |bet| convert_money(bet) }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
