module OddsFeed
  module Radar
    class EventScopesService < ApplicationService
      attr_reader :title,
                  :country,
                  :tournament,
                  :season

      def initialize(payload)
        @payload = payload
        @title = nil
        @country = nil
        @tournament = nil
        @season = nil
      end

      def call
        find_or_create_title!(@payload['sport'])
        find_or_create_country!(@payload['category'])
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

      def find_or_create_country!(payload)
        return unless payload_valid_for?('Country', payload)

        @country = EventScope.new(kind: :country,
                                  external_id: payload['id'],
                                  title: @title,
                                  name: payload['name'])
        EventScope.create_or_update_on_duplicate(@country)
      end

      def find_or_create_tournament!(payload)
        return unless payload_valid_for?('Tournament', payload)

        @tournament = EventScope.new(kind: :tournament,
                                     external_id: payload['id'],
                                     title: @title,
                                     event_scope: @country,
                                     name: payload['name'])
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
        Rails.logger.debug "#{scope} data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ["#{scope} is missing", @payload]
          return false
        end

        true
      end
    end
  end
end
