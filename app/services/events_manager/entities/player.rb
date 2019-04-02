module EventsManager
  module Entities
    class Player < SimpleEntity
      def full_name
        attribute(@payload, 'full_name')
      end
    end
  end
end
