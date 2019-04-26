module BetExternalValidation
  class Service < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def call
      delay = live_bet_delay if @bet.odd.market.event.producer&.live?
      return publisher.perform_async([@bet.id]) unless delay

      publisher.perform_in(delay.seconds, [@bet.id])
    end

    private

    def fetch_global_limit
      BettingLimit
        .find_by(
          customer: @customer,
          title: nil
        )
    end

    def fetch_limit_by_title
      BettingLimit
        .find_by(
          customer: @customer,
          title: @bet.odd.market.event.title
        )
    end

    def live_bet_delay
      delays = [
        fetch_global_limit&.live_bet_delay,
        fetch_limit_by_title&.live_bet_delay
      ].compact

      delays&.max
    end

    def publisher
      return BetExternalValidation::PublisherStub if Mts::Mode.stubbed?

      Mts::ValidationMessagePublisherWorker
    end
  end
end
