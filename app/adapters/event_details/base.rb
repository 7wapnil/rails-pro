module EventDetails
  class Base
    def initialize(event)
      @event = event
    end

    def competitors
      raise NotImplementedError
    end
  end
end
