# frozen_string_literal: true

module Bets
  class Settle < ApplicationService
    include JobLogger

    ACTIVE_VOID_FACTOR = 1
    SUPPORTED_VOID_FACTORS = [nil, ACTIVE_VOID_FACTOR].freeze
    WIN_RESULT = '1'

    delegate :customer_bonus, to: :bet

    def initialize(bet:, void_factor:, result:)
      @bet = bet
      @raw_void_factor = void_factor
      @result = result
    end

    def call
      ActiveRecord::Base.transaction do
        lock_important_entities!
        validate_settlement!
        settle_bet!
        perform_payout!
        settle_customer_bonus!
      end
    rescue ::Bets::NotAcceptedError => error
      raise error
    rescue StandardError => error
      bet.send_to_manual_settlement!(error.message)
      raise error
    end

    private

    attr_reader :bet, :raw_void_factor, :result, :entry_request

    def lock_important_entities!
      bet.lock!
      customer_bonus&.lock!
    end

    def validate_settlement!
      validate_bet!
      validate_void_factor!
    end

    def validate_bet!
      return if bet.accepted?

      raise ::Bets::NotAcceptedError,
            I18n.t('errors.messages.bets.not_accepted')
    end

    def validate_void_factor!
      return if SUPPORTED_VOID_FACTORS.include?(void_factor)

      raise ::Bets::NotSupportedError,
            I18n.t('errors.messages.bets.not_supported_void_factor')
    end

    def void_factor
      @void_factor ||= Float(raw_void_factor)
    rescue TypeError, ArgumentError
      raw_void_factor
    end

    def settle_bet!
      bet.settle!(
        settlement_status: settlement_status,
        void_factor: void_factor
      )
    end

    def settlement_status
      return Bet::VOIDED if void_factor == ACTIVE_VOID_FACTOR

      result == WIN_RESULT ? Bet::WON : Bet::LOST
    end

    def perform_payout!
      create_entry_request!

      return unless entry_request

      EntryRequests::BetSettlementService.call(entry_request: entry_request)
    end

    def create_entry_request!
      return create_win_entry_request! if bet.won?

      create_refund_entry_request! if bet.voided?
    end

    def create_win_entry_request!
      @entry_request = ::EntryRequests::Factories::WinPayout.call(
        origin: bet,
        kind: EntryRequest::WIN,
        mode: EntryRequest::INTERNAL,
        amount: bet.win_amount,
        comment: "WIN for bet #{bet.id}"
      )
    end

    def create_refund_entry_request!
      @entry_request = ::EntryRequests::Factories::Common.call(
        origin: bet,
        kind: EntryRequest::REFUND,
        mode: EntryRequest::INTERNAL,
        amount: bet.refund_amount,
        comment: "REFUND for bet #{bet.id}"
      )
    end

    def settle_customer_bonus!
      CustomerBonuses::BetSettlementService.call(bet)
    end
  end
end
