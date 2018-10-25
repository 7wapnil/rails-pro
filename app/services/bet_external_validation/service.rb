module BetExternalValidation
  class Service
    def self.call(bet)
      Mts::MessagePublisherWorker.perform_async([bet.id])
    end
  end
end
