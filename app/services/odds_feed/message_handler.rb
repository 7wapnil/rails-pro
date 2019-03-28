module OddsFeed
  class MessageHandler
    def initialize(payload, configuration: {})
      @payload = payload
      @configuration = configuration
    end

    def handle
      raise NotImplementedError
    end
  end
end
