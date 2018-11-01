module OddsFeed
  module Radar
    class EventScopeService < ApplicationService
      def initialize(payload)
        @payload = payload
      end

      def call
        find_or_create_title!(@payload['sport'])
        find_or_create_country!(@payload['category'])
        find_or_create_tournament!(@payload)
        find_or_create_season!(@payload['current_season'])
      end

      private

      def find_or_create_title!(title)
        Rails.logger.info "Title data received: #{title}"

        unless title
          Rails.logger.info 'Title is missing, exiting'
          return
        end

        @title = Title.find_or_create_by!(
          external_id: title['id']
        ) do |object|
          object.name = title['name']
          object.kind = OddsFeed::Radar::SportKindMappingService.call(
            title['name']
          )
        end
      end

      def find_or_create_country!(country)
        Rails.logger.info "Country data received: #{country}"

        unless country
          Rails.logger.info 'Country is missing, exiting'
          return
        end

        @country = EventScope.find_or_create_by!(
          external_id: country['id']
        ) do |event_scope|
          event_scope.title = @title
          event_scope.name = country['name']
          event_scope.kind = :country
        end
      end

      def find_or_create_tournament!(tournament)
        Rails.logger.info "Tournament data received: #{tournament}"

        unless tournament
          Rails.logger.info 'Tournament is missing, exiting'
          return
        end

        @tournament = EventScope.find_or_create_by!(
          external_id: tournament['id']
        ) do |event_scope|
          event_scope.title = @title
          event_scope.event_scope = @country
          event_scope.name = tournament['name']
          event_scope.kind = :tournament
        end
      end

      def find_or_create_season!(season)
        Rails.logger.info "Season data received: #{season}"

        unless season
          Rails.logger.info 'Season is missing, exiting'
          return
        end

        @season = EventScope.find_or_create_by!(
          external_id: season['id']
        ) do |event_scope|
          event_scope.title = @title
          event_scope.event_scope = @tournament
          event_scope.name = season['name']
          event_scope.kind = :season
        end
      end
    end
  end
end
