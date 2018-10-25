module BetExternalValidation
  class PublisherStub
    def self.perform_async(bets)
      Thread.new do
        bets.each(&:finish_external_validation_with_acceptance!)
      end
    end
  end
end
