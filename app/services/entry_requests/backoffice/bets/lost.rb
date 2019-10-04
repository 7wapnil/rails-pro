# frozen_string_literal: true

module EntryRequests
  module Backoffice
    module Bets
      class Lost < SettlementService
        delegate :winning, to: :bet

        private

        attr_reader :entry_request

        def create_entry_requests!
          create_entry_request_for!(winning) if bet.won?
          create_entry_request_for!(placement_entry) if voided?

          @entry_requests = Array.wrap(entry_request)
        end

        def recalculate_bonus_rollover!; end

        def update_bet_settlement_status!
          bet.settle_manually!(settlement_status: Bet::LOST)
        end

        def create_entry_request_for!(entry)
          @entry_request = EntryRequest.create!(request_attributes(entry))
        end

        def request_attributes(entry)
          {
            kind: EntryKinds::MANUAL_BET_CANCEL,
            mode: EntryRequest::INTERNAL,
            amount: -entry.amount.abs,
            real_money_amount: -entry.real_money_amount.abs,
            bonus_amount: -entry.bonus_amount.abs,
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
