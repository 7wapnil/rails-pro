module Radar
  class EventScopesCreatingWorker < ApplicationWorker
    def perform(payload)
      OddsFeed::Radar::EventScopesService.call(payload)
    end
  end
end
