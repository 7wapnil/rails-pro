module Mts
  class ValidationMessagePublisherStubWorker < ApplicationWorker
    def perform(ids)
      sleep(2)
      Bet.where(id: ids).each(&:finish_external_validation_with_acceptance!)
    end
  end
end
