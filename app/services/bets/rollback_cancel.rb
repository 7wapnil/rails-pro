# frozen_string_literal: true

module Bets
  # rubocop:disable Metrics/ClassLength
  class RollbackCancel < ApplicationService
    def initialize(bet_leg:, bet:)
      @bet_leg = bet.bet_legs.find { |leg| leg.id == bet_leg.id }
      @bet = bet
    end

    def call
      ActiveRecord::Base.transaction do
        lock_important_entities!

        rollback_bet_leg_status!
        proceed_rollback_cancellation!
        handle_bonus_rollover!
      end
    end

    private

    attr_reader :bet_leg, :bet

    def lock_important_entities!
      bet.lock!
      bet_leg.lock!
      bet.customer_bonus&.lock!
    end

    def rollback_bet_leg_status!
      return bet_leg.pending_manual_settlement! if bet_leg.unresolved?

      bet_leg.update(status: nil)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    def proceed_rollback_cancellation!
      case bet
      when :pending_manual_settlement?.to_proc
        handle_unresolved_bet
      when :cancelled_by_system?.to_proc
        handle_cancelled_by_system_bet
      when :accepted?.to_proc
        handle_accepted_bet
      when :voided?.to_proc
        handle_voided_bet
      when :lost?.to_proc
        handle_lost_bet
      when :won?.to_proc
        handle_won_bet
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

    def handle_bonus_rollover!
      return rollback_bonus_rollover! if pending_bet_state?

      settle_customer_bonus!
    end

    def handle_unresolved_bet
      return unless !bet.lost? && bet_leg.lost?

      rollback_money!
      resend_to_manual_settlement!(Bet::LOST)
    end

    def handle_cancelled_by_system_bet
      rollback_money! unless bet_leg.voided?
      return rollback_with_acceptance! if bet_leg.settlement_status.nil?

      rollback_with_settlement!
    end

    def handle_accepted_bet
      return send_to_manual_settlement! if bet_leg.unresolved?
      return unless bet_leg.lost?

      settle!(Bet::LOST)
      settle_customer_bonus!
    end

    def handle_voided_bet
      return send_to_manual_settlement! if bet_leg.unresolved?

      rollback_money! unless bet_leg.voided?
      return resettle!(Bet::LOST) if bet_leg.lost?
      return unless bet_leg.won?

      proceed_entry_request(win_entry_request)
      resettle!(Bet::WON)
    end

    def handle_lost_bet
      return unless bet_leg.unresolved?

      resend_to_manual_settlement!(bet.settlement_status)
    end

    def handle_won_bet
      return if bet_leg.voided?

      rollback_money!
      return send_to_manual_settlement! if bet_leg.unresolved?
      return resettle!(Bet::LOST) if bet_leg.lost?
      return unless bet_leg.won?

      proceed_entry_request(win_entry_request)
      resettle!(Bet::WON)
    end

    def pending_bet_state?
      bet.accepted? || bet.pending_manual_settlement? && !bet.lost?
    end

    def settle_customer_bonus!
      CustomerBonuses::BetSettlementService.call(bet)
    end

    def rollback_bonus_rollover!
      CustomerBonuses::RollbackBonusRolloverService.call(bet: bet)
    end

    def rollback_money!
      EntryRequests::Factories::RollbackBetCancellation
        .call(bet: bet, bet_leg: bet_leg)
        .each { |request| proceed_entry_request(request) }
    end

    def resend_to_manual_settlement!(status)
      bet.resend_to_manual_settlement!(settlement_status: status)
    end

    def rollback_with_acceptance!
      bet.rollback_system_cancellation_with_acceptance!
    end

    def rollback_with_settlement!(status = bet_leg.settlement_status)
      bet.rollback_system_cancellation_with_settlement!(
        settlement_status: status
      )
    end

    def send_to_manual_settlement!
      bet.send_to_manual_settlement!
    end

    def settle!(status)
      bet.settle!(settlement_status: status)
    end

    def resettle!(status)
      bet.resettle!(settlement_status: status)
    end

    def proceed_entry_request(request)
      EntryRequests::ProcessingService.call(entry_request: request)
    end

    def win_entry_request
      ::EntryRequests::Factories::WinPayout.call(
        origin: bet,
        kind: EntryRequest::WIN,
        mode: EntryRequest::INTERNAL,
        amount: bet.amount * bet.odd_value,
        comment: "WIN for bet #{bet.id}"
      )
    end
  end
  # rubocop:enable Metrics/ClassLength
end
