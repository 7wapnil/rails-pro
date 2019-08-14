# frozen_string_literal: true

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
        @players ||= ensure_players.map do |payload|
          EventsManager::Entities::Player.new(payload)
        end
      end

      private

      def ensure_players
        Array.wrap(attribute(profile, 'players', 'player'))
      end

      def profile
        @profile ||= attribute(@payload, 'competitor_profile') ||
                     attribute(@payload, 'simpleteam_profile')

        return @profile if @profile

        log(:error, message: 'Competitor profile is malformed',
                    payload: @payload)
        {}
      end

      def fixture
        attribute!(profile, 'competitor')
      end
    end
  end
end
