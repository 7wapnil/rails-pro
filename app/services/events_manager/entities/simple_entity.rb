module EventsManager
  module Entities
    class SimpleEntity < BaseEntity
      def id
        attribute!(@payload, 'id')
      end

      def name
        attribute!(@payload, 'name')
      end

      def qualifier
        attribute!(@payload, 'qualifier')
      end
    end
  end
end
