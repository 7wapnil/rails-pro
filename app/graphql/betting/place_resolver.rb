# frozen_string_literal: true

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

      raise entry_request.result['message'] if entry_request.failed?

      ::EntryRequests::BetPlacementWorker.perform_in(3.second, entry_request.id)

      OpenStruct.new(id: bet_payload[:oddId],
                     message: nil,
                     success: true,
                     bet: bet)
    rescue StandardError => e
      bet&.register_failure!(e.message)

      OpenStruct.new(id: bet_payload[:oddId],
                     message: failure_message,
                     success: false)
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
      Odd.active.find(bet_payload[:oddId])
    end

    def failure_message
      I18n.t('errors.messages.graphql.betting.place.failure')
    end
  end
end
