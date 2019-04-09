# frozen_string_literal: true

module EntryRequests
  module Factories
    class BetPlacement < ApplicationService
      delegate :customer_bonus, :odd, :market, to: :bet
      delegate :applied?, to: :customer_bonus, allow_nil: true, prefix: true

      def initialize(bet:, initiator: nil)
        @bet = bet
        @passed_initiator = initiator
      end

      def call
        create_entry_request!
        validate_entry_request!
        create_balance_request!

        entry_request
      end

      private

      attr_reader :bet, :passed_initiator, :entry_request

      def real_amount
        @real_amount ||= amount_calculations[:real_money]
      end

      def amount_calculations
        @amount_calculations ||= BalanceCalculations::BetWithBonus
                                 .call(bet, ratio)
      end

      def ratio
        return 1.0 unless customer_bonus_applied?

        wallet.ratio_with_bonus
      end

      def wallet
        @wallet ||= Wallet.find_or_create_by(
          customer_id: bet.customer_id,
          currency_id: bet.currency_id
        )
      end

      def create_entry_request!
        @entry_request = EntryRequest.create!(entry_request_attributes)
      end

      def entry_request_attributes
        bet_attributes.merge(
          initiator: initiator,
          kind: EntryRequest::BET,
          mode: EntryRequest::SYSTEM,
          comment: comment
        )
      end

      def bet_attributes
        {
          amount: bet.amount,
          currency: bet.currency,
          customer: bet.customer,
          origin: bet
        }
      end

      def initiator
        passed_initiator || bet.customer
      end

      def comment
        "Withdrawal #{bet.amount} #{wallet.currency} " \
        "for #{bet.customer}#{initiator_comment_suffix}"
      end

      def initiator_comment_suffix
        " by #{passed_initiator}" if passed_initiator
      end

      def validate_entry_request!
        check_if_odd_active! && check_if_market_not_suspended!
      end

      def check_if_odd_active!
        return true if odd.active?

        entry_request
          .register_failure!(I18n.t('errors.messages.bet_odd_inactive'))
      end

      def check_if_market_not_suspended!
        return true unless market.suspended?

        entry_request
          .register_failure!(I18n.t('errors.messages.market_suspended'))
      end

      def create_balance_request!
        BalanceRequestBuilders::Bet.call(entry_request, amount_calculations)
      end
    end
  end
end
