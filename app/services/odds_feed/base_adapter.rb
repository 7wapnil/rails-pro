module OddsFeed
  class BaseAdapter
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end
  end
end
