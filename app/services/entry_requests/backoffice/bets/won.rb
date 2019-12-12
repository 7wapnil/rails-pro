# frozen_string_literal: true

module EntryRequests
  module Backoffice
    module Bets
      class Won < SettlementService
        private

        attr_reader :placement_entry_request, :winning_entry_request

        def create_entry_requests!
          create_bet_entry_request! unless placed? && !voided?
          create_win_entry_request!

          @entry_requests = [placement_entry_request, winning_entry_request]
        end

        def recalculate_bonus_rollover!
          return unless customer_bonus

          CustomerBonuses::BetSettlementService.call(bet)
        end

        def update_bet_settlement_status!
          bet.settle_manually!(settlement_status: Bet::WON)
        end

        def create_bet_entry_request!
          @placement_entry_request = EntryRequest
                                     .create!(bet_request_attributes)
        end

        def create_win_entry_request!
          @winning_entry_request = ::EntryRequests::Factories::WinPayout.call(
            origin: bet,
            kind: EntryRequest::WIN,
            mode: EntryRequest::INTERNAL,
            amount: bet.amount * bet.odd_value,
            comment: comment,
            initiator: initiator
          )
        end

        def bet_request_attributes
          {
            kind: EntryKinds::MANUAL_BET_PLACEMENT,
            mode: EntryRequest::INTERNAL,
            amount: placement_entry.amount,
            real_money_amount: placement_entry.real_money_amount,
            bonus_amount: placement_entry.bonus_amount,
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
