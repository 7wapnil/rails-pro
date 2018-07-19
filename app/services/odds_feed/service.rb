module OddsFeed
  class Service < ApplicationService
    def initialize(event_data)
      @event_data = event_data
    end

    def call
    end
  end
end
