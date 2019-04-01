module EventsManager
  module Entities
    class BaseEntity
      def initialize(payload)
        @payload = payload
      end

      def to_s
        @payload
      end
    end
  end
end
