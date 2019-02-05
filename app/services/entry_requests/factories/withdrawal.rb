module EntryRequests
  module Factories
    class Withdrawal < ApplicationService
      DEFAULT_RATIO = 1.0

      delegate :customer_bonus, to: :bet
      delegate :applied?, to: :customer_bonus, allow_nil: true, prefix: true

      def initialize(bet:, initiator: nil)
        @bet = bet
        @passed_initiator = initiator
      end

      def call
        return no_amount! if !real_amount || real_amount.zero?

        create_entry_request!
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
        return DEFAULT_RATIO unless customer_bonus_applied?

        wallet.ratio_with_bonus
      end

      def wallet
        @wallet ||= Wallet.find_or_create_by(
          customer_id: bet.customer_id,
          currency_id: bet.currency_id
        )
      end

      def no_amount!
        raise ArgumentError, I18n.t('errors.messages.real_money_blank_amount')
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
        passed_initiator ? " by #{passed_initiator}" : ''
      end

      def create_balance_request!
        BalanceRequestBuilders::Bet.call(entry_request, amount_calculations)
      end
    end
  end
end
