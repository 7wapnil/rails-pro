module OddsFeed
  class MessageHandler
    def initialize(payload)
      @payload = payload
    end

    def handle
      raise NotImplementedError
    end
  end
end
