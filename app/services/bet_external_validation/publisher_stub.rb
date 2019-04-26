module BetExternalValidation
  class PublisherStub
    def self.perform_async(bet_ids)
      Bet.where(id: bet_ids).each(&:finish_external_validation_with_acceptance!)
    end

    def self.perform_in(_delay, bet_ids)
      Bet.where(id: bet_ids).each(&:finish_external_validation_with_acceptance!)
    end
  end
end
