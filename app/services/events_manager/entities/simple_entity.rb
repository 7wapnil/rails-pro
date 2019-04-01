module EventsManager
  module Entities
    class SimpleEntity < BaseEntity
      def id
        @payload['id']
      end

      def name
        @payload['name']
      end
    end
  end
end
