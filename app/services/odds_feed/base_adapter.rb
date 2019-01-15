module OddsFeed
  class BaseAdapter
    attr_reader :payload

    def initialize(payload = nil)
      @payload = payload
    end

    def result
      raise NotImplementedError
    end
  end
end
