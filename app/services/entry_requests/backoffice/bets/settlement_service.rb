# frozen_string_literal: true

module EntryRequests
  module Backoffice
    module Bets
      class SettlementService < ApplicationService
        PLACED_BET_STATUSES = [
          Bet::VALIDATED_INTERNALLY,
          Bet::SENT_TO_EXTERNAL_VALIDATION,
          Bet::ACCEPTED,
          Bet::PENDING_CANCELLATION,
          Bet::PENDING_MANUAL_SETTLEMENT,
          Bet::SETTLED,
          Bet::MANUALLY_SETTLED
        ].freeze

        REFUNDED_BET_STATUSES = [
          Bet::CANCELLED,
          Bet::CANCELLED_BY_SYSTEM,
          Bet::PENDING_MTS_CANCELLATION,
          Bet::REJECTED,
          Bet::FAILED,
          Bet::MANUALLY_SETTLED
        ].freeze

        delegate :placement_entry, to: :bet
        delegate :customer_bonus, to: :bet
        delegate :customer, to: :bet

        def initialize(bet:, initiator: nil, comment: nil)
          @bet = bet
          @initiator = initiator
          @comment = comment
        end

        def call
          ActiveRecord::Base.transaction do
            lock_important_entities!
            create_entry_requests!
            proceed_entry_requests!
            update_bet_settlement_status!
            recalculate_bonus_rollover!
            log_initiator_activity!
          end
        end

        private

        attr_reader :bet, :entry_requests, :initiator, :comment

        def lock_important_entities!
          bet.lock!
          customer_bonus&.lock!
        end

        def create_entry_requests!
          raise NotImplementedError, 'Define #create_entry_requests!'
        end

        def proceed_entry_requests!
          entry_requests.compact.each(&method(:authorize_wallet_entry!))
        end

        def recalculate_bonus_rollover!
          raise NotImplementedError, 'Define #recalculate_bonus_rollover!'
        end

        def update_bet_settlement_status!
          raise NotImplementedError, 'Define #update_bet_settlement_status!'
        end

        def log_initiator_activity!
          entry_requests.compact.each do |request|
            initiator.log_event(:entry_request_created, request, customer)
          end
        end

        def authorize_wallet_entry!(entry_request)
          return if WalletEntry::AuthorizationService.call(entry_request)

          raise ::Bets::AuthorizeWalletEntryError,
                I18n.t('errors.messages.bets.cannot_be_proceeded')
        end

        def placed?
          return false if bet.voided?

          PLACED_BET_STATUSES.member?(bet.status)
        end

        def voided?
          return false if bet.won?

          REFUNDED_BET_STATUSES.member?(bet.status) || bet.voided?
        end
      end
    end
  end
end
