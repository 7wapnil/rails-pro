# frozen_string_literal: trueInitial

module EntryRequests
  module Backoffice
    module Bets
      class Voided < SettlementService
        delegate :winning, to: :bet

        private

        attr_reader :bet_cancel_request, :win_cancel_request

        def create_entry_requests!
          create_bet_cancel_request! if placed?
          create_win_cancel_request! if bet.won?

          @entry_requests = [bet_cancel_request, win_cancel_request].compact
        end

        def recalculate_bonus_rollover!
          return unless customer_bonus

          CustomerBonuses::RollbackBonusRolloverService.call(bet: bet)
        end

        def update_bet_settlement_status!
          bet.settle_manually!(settlement_status: Bet::VOIDED)
        end

        def create_bet_cancel_request!
          @bet_cancel_request = EntryRequest
                                .create!(bet_cancel_request_attributes)
        end

        def bet_cancel_request_attributes
          {
            kind: EntryKinds::MANUAL_BET_CANCEL,
            mode: EntryRequest::INTERNAL,
            amount: placement_entry.amount.abs,
            real_money_amount: placement_entry.real_money_amount.abs,
            bonus_amount: placement_entry.bonus_amount.abs,
            comment: comment,
            customer_id: bet.customer_id,
            currency_id: bet.currency_id,
            origin: bet,
            initiator: initiator
          }
        end

        def create_win_cancel_request!
          @win_cancel_request = EntryRequest
                                .create!(win_cancel_request_attributes)
        end

        def win_cancel_request_attributes
          {
            kind: EntryKinds::MANUAL_BET_CANCEL,
            mode: EntryRequest::INTERNAL,
            amount: -winning.amount,
            real_money_amount: -winning.real_money_amount.abs,
            bonus_amount: -winning.bonus_amount.abs,
            comment: comment,
            customer_id: bet.customer_id,
            currency_id: bet.currency_id,
            origin: bet,
            initiator: initiator
          }
        end
      end
    end
  end
end
