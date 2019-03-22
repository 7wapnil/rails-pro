module OddsFeed
  class MessageHandler
    attr_reader :profiler

    def initialize(payload, profiler = nil, configuration: {})
      @payload = payload
      @configuration = configuration
      @profiler = profiler
    end

    def handle
      raise NotImplementedError
    end
  end
end
