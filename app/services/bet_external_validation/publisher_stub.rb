module BetExternalValidation
  class PublisherStub
    def perform(bet_ids)
      accept_bets(bet_ids)
    end

    def self.perform_async(bet_ids)
      new.accept_bets(bet_ids)
    end

    def self.perform_in(_delay, bet_ids)
      new.accept_bets(bet_ids)
    end

    def accept_bets(bet_ids)
      sleep(3)
      Bet.where(id: bet_ids).each(&:finish_external_validation_with_acceptance!)
    end
  end
end
