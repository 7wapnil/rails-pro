module EventsManager
  module Entities
    class Competitor < BaseEntity
      def id
        fixture['id']
      end

      def name
        fixture['name']
      end

      def details
        { country: fixture['country'] }
      end

      def players
        @players ||= profile['players']['player'].map do |payload|
          EventsManager::Entities::Player.new(payload)
        end
      end

      private

      def profile
        attribute!(@payload, 'competitor_profile')
      end

      def fixture
        attribute!(profile, 'competitor')
      end
    end
  end
end
