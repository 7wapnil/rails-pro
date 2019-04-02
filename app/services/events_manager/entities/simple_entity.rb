module EventsManager
  module Entities
    class SimpleEntity < BaseEntity
      def id
        attribute!(@payload, 'id')
      end

      def name
        attribute!(@payload, 'name')
      end
    end
  end
end
