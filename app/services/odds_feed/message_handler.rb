module OddsFeed
  class MessageHandler
    def initialize(payload, profiler = nil, configuration: {})
      @payload = payload
      @configuration = configuration
    end

    def handle
      raise NotImplementedError
    end
  end
end
