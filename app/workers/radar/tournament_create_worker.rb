module Radar
  class TournamentCreateWorker < ApplicationWorker
    def perform(payload)
      OddsFeed::Radar::EventScopeService.call(payload)
    end
  end
end
