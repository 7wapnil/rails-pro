# frozen_string_literal: true

module Mts
  class RandomBetPlacementWorker < ApplicationWorker
    def perform # rubocop:disable Metrics/MethodLength
      return unless ENV['MTS_RUN_RANDOM_BET_PLACEMENT'].eql?('true')

      customer = Customer.first

      odd = Odd
            .active
            .joins(market: :event)
            .where(
              markets: { status: :active },
              events: { start_at: [Time.zone.now..Date.current.end_of_day] }
            )
            .sample

      return if odd.blank?

      bet_args = [{
        amount: 1,
        currencyCode: 'EUR',
        oddId: odd.id,
        oddValue: odd.value
      }]

      Betting::PlaceResolver.call(
        args: { bets: bet_args },
        impersonated_by: nil,
        customer: customer
      )
    end
  end
end
