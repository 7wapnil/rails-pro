module OddsFeed
  module Radar
    class AliveHandler < RadarMessageHandler
      def handle
        raise NotImplementedError
      end
    end
  end
end
