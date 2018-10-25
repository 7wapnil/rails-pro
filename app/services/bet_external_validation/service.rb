module BetExternalValidation
  class Service < ApplicationService
    def initialize(bet)
      @bet = bet
    end

    def call
      publisher.perform_async([@bet.id])
    end

    private

    def publisher
      return BetExternalValidation::PublisherStub if Mts::Mode.stubbed?

      Mts::MessagePublisherWorker
    end
  end
end
