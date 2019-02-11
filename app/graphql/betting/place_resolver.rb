module Betting
  class PlaceResolver < ApplicationService
    def initialize(args:, impersonated_by:, customer:)
      @bet_payloads = args[:bets]
      @impersonated_by = impersonated_by
      @customer = customer
    end

    def call
      bet_payloads.map { |payload| collect_bet(payload) }
    end

    private

    attr_reader :bet_payloads, :impersonated_by, :customer

    def collect_bet(bet_payload)
      bet = create_bet!(bet_payload)
      entry_request = create_entry_request!(bet)

      ::EntryRequests::BetPlacementService.call(entry_request: entry_request)

      OpenStruct.new(id: bet_payload[:oddId],
                     message: nil,
                     success: true,
                     bet: bet)
    rescue StandardError => e
      bet&.register_failure!(e.message)

      OpenStruct.new(id: bet_payload[:oddId],
                     message: e.message,
                     success: false)
    end

    def create_bet!(bet_payload)
      Bet.create!(bet_attributes(bet_payload))
    end

    def create_entry_request!(bet)
      @entry_request = ::EntryRequests::Factories::BetPlacement.call(
        bet: bet,
        initiator: impersonated_by
      )
    end

    def bet_attributes(bet_payload)
      currency = Currency.find_by!(code: bet_payload[:currencyCode])
      amount = bet_payload[:amount]
      {
        customer: customer,
        odd: find_odd(bet_payload),
        currency: currency,
        amount: amount,
        odd_value: bet_payload[:oddValue],
        status: Bet::INITIAL,
        customer_bonus: customer.active_bonus
      }
    end

    def find_odd(bet_payload)
      Odd.find(bet_payload[:oddId])
    end
  end
end
