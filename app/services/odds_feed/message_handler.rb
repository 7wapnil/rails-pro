module OddsFeed
  class MessageHandler
    attr_reader :profiler

    def initialize(payload, signed_profiler = nil, configuration: {})
      @payload = payload
      @configuration = configuration
      @profiler = GlobalID::Locator.locate_signed signed_profiler
    end

    def handle
      raise NotImplementedError
    end
  end
end
