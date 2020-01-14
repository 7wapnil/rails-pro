# frozen_string_literal: true

module Bets
  class Place < ApplicationService
    include JobLogger

    def initialize(payload:, impersonated_by:, customer:, combo_bets:)
      @payload = payload
      @impersonated_by = impersonated_by
      @customer = customer
      @combo_bets = combo_bets
      @odds = payload[:odds].to_a
    end

    def call
      find_or_create_wallet!

      create_bet!
      register_bet!

      bet
    rescue StandardError => error
      register_bet_failure(error)

      raise Bets::PlacementError.new(error.message, bet: bet, odd_id: odd_id)
    end

    private

    attr_reader :payload, :impersonated_by, :customer, :combo_bets, :odds
    attr_reader :wallet, :bet, :entry_request

    alias_method :combo_bets?, :combo_bets

    def find_or_create_wallet!
      @wallet = Wallets::FindOrCreate
                .call(customer: customer, currency: currency)
    end

    def currency
      @currency ||= Currency.find_by!(code: payload[:currencyCode])
    end

    def create_bet!
      @bet = Bet.create!(bet_attributes)
    end

    def bet_attributes
      {
        customer: customer,
        status: Bet::INITIAL,
        combo_bets: combo_bets?,
        currency: currency,
        amount: payload[:amount],
        base_currency_amount: base_currency_amount,
        odds_change: payload[:oddsChange],
        customer_bonus: assigned_customer_bonus,
        bet_legs_attributes: bet_legs_attributes
      }
    end

    def base_currency_amount
      Exchanger::Converter.call(payload[:amount], currency.code)
    end

    def assigned_customer_bonus
      return unless wallet.bonus_balance.positive?

      CustomerBonus.active.find_by(
        sportsbook: true,
        customer: customer,
        wallet: wallet
      )
    end

    def bet_legs_attributes
      odds.map do |odd_payload|
        odd = Odd.active.find(odd_payload[:id])

        {
          odd: odd,
          odd_value: payload[:oddsChange] ? odd.value : odd_payload[:value]
        }
      end
    end

    def register_bet!
      create_entry_request!

      raise_registration_error! if entry_request.failed?

      ::EntryRequests::BetPlacementWorker.perform_async(entry_request.id)
    end

    def create_entry_request!
      @entry_request = ::EntryRequests::Factories::BetPlacement.call(
        bet: bet,
        initiator: impersonated_by
      )
    end

    def raise_registration_error!
      raise Bets::RegistrationError.new(
        entry_request.result['message'],
        odd_ids: entry_request.result['odds']
      )
    end

    def odd_id
      odds.first&.id unless combo_bets?
    end

    def register_bet_failure(error)
      bet&.register_failure!(
        error.message,
        code: Bets::Notification::PLACEMENT_ERROR
      )
    end
  end
end
