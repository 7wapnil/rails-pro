module OddsFeed
  module Radar
    class EventScopesService < ApplicationService
      include JobLogger

      attr_reader :title,
                  :category,
                  :tournament,
                  :season

      def initialize(payload)
        @payload = payload
        @title = nil
        @category = nil
        @tournament = nil
        @season = nil
      end

      def call
        find_or_create_title!(@payload['sport'])
        find_or_create_category!(@payload['category'])
        find_or_create_tournament!(@payload)
        find_or_create_season!(@payload['current_season'])
      end

      private

      def find_or_create_title!(payload)
        return unless payload_valid_for?('Title', payload)

        @title = Title.new(external_id: payload['id'],
                           name: payload['name'],
                           kind: SportKind.from_title(payload['name']))

        Title.create_or_update_on_duplicate(@title)
      end

      def find_or_create_category!(payload)
        return unless payload_valid_for?('Category', payload)

        @category = EventScope.new(
          kind:        EventScope::CATEGORY,
          external_id: payload['id'],
          title:       @title,
          name:        payload['name']
        )
        EventScope.create_or_update_on_duplicate(@category)
      end

      def find_or_create_tournament!(payload)
        return unless payload_valid_for?('Tournament', payload)

        @tournament = EventScope.new(
          kind:        EventScope::TOURNAMENT,
          external_id: payload['id'],
          title:       @title,
          event_scope: @category,
          name:        payload['name']
        )
        EventScope.create_or_update_on_duplicate(@tournament)
      end

      def find_or_create_season!(payload)
        return unless payload_valid_for?('Season', payload)

        @season = EventScope.new(kind: :season,
                                 external_id: payload['id'],
                                 title: @title,
                                 event_scope: @tournament,
                                 name: payload['name'])
        EventScope.create_or_update_on_duplicate(@season)
      end

      def payload_valid_for?(scope, payload)
        log_job_message(:debug, "#{scope} data received: #{payload}")

        unless payload.is_a?(Hash)
          log_job_message(:warn, ["#{scope} is missing", @payload])
          return false
        end

        true
      end
    end
  end
end
