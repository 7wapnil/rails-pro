# frozen_string_literal: true

module Betting
  class PlaceResolver < ApplicationService
    def initialize(bets_payload:, impersonated_by:, customer:, combo_bets:)
      @bets_payload = bets_payload
      @impersonated_by = impersonated_by
      @customer = customer
      @combo_bets = combo_bets
    end

    def call
      return collect_bet(bets_payload) if combo_bets?

      bets_payload.map { |payload| collect_bet(payload) }
    end

    private

    attr_reader :bets_payload, :impersonated_by, :customer, :combo_bets
    alias_method :combo_bets?, :combo_bets

    def collect_bet(bet_payload)
      bet = create_bet!(bet_payload)
      request_for_bet!(bet)

      OpenStruct.new(success: true,
                     bet: bet.decorate)
    rescue StandardError => e
      bet&.register_failure!(e.message,
                             code: Bets::Notification::PLACEMENT_ERROR)

      OpenStruct.new(message: failure_message,
                     success: false,
                     bet: bet&.decorate,
                     odd_id: odd_id(bet_payload))
    end

    def request_for_bet!(bet)
      entry_request = create_entry_request!(bet)

      raise_placement_error!(entry_request) if entry_request.failed?

      ::EntryRequests::BetPlacementWorker.perform_async(entry_request.id)
    end

    def create_bet!(bet_payload)
      Bet.create!(bet_attributes(bet_payload))
    end

    def create_entry_request!(bet)
      ::EntryRequests::Factories::BetPlacement.call(
        bet: bet,
        initiator: impersonated_by
      )
    end

    def raise_placement_error!(entry_request)
      raise Bets::PlacementError.new(
        entry_request.result['message'],
        odd_ids: entry_request.result['odds']
      )
    end

    def bet_attributes(bet_payload)
      currency = Currency.find_by!(code: bet_payload[:currencyCode])
      amount = bet_payload[:amount]
      base_currency_amount = Exchanger::Converter.call(amount, currency.code)
      {
        **common_bet_attributes,
        currency: currency,
        amount: amount,
        base_currency_amount: base_currency_amount,
        odds_change: bet_payload[:oddsChange],
        bet_legs_attributes: bet_legs_attributes(bet_payload[:odds],
                                                 bet_payload[:oddsChange])
      }
    end

    def failure_message
      I18n.t('bets.notifications.placement_error')
    end

    def odd_id(bet_payload)
      return if combo_bets?

      bet_payload.odds.first.id
    rescue StandardError
      nil
    end

    def common_bet_attributes
      {
        customer: customer,
        status: Bet::INITIAL,
        customer_bonus: customer.active_bonus,
        combo_bets: combo_bets
      }
    end

    def bet_legs_attributes(odds, odds_change)
      odds.map do |odd_payload|
        odd = find_odd(odd_payload)

        {
          odd: odd,
          odd_value: odds_change ? odd.value : odd_payload[:value]
        }
      end
    end

    def find_odd(odd_payload)
      Odd.active.find(odd_payload[:id])
    end
  end
end
