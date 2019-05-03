# frozen_string_literal: true

module BetExternalValidation
  class Service < ApplicationService
    delegate :customer, :producer, to: :bet

    def initialize(bet)
      @bet = bet
    end

    def call
      return publisher.perform_async(bet.id) unless live_bet_delay

      publisher.perform_in(live_bet_delay.seconds, bet.id)
    end

    private

    attr_reader :bet

    def live_bet_delay
      return @live_bet_delay unless producer&.live?

      @live_bet_delay ||= [global_live_bet_delay, title_live_bet_delay].max
    end

    def global_live_bet_delay
      BettingLimit
        .find_by(customer: customer, title: nil)
        &.live_bet_delay
    end

    def title_live_bet_delay
      BettingLimit
        .find_by(customer: customer, title: bet.odd.market.event.title)
        &.live_bet_delay
    end

    def publisher
      return Mts::ValidationMessagePublisherStubWorker if Mts::Mode.stubbed?

      Mts::ValidationMessagePublisherWorker
    end
  end
end
