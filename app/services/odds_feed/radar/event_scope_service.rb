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

      def find_or_create_title!(payload)
        Rails.logger.debug "Title data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ['Title is missing, exiting', @payload]
          return
        end

        @title = Title.find_or_initialize_by(external_id: title_id) do |title|
          title.name = payload['name']
          title.kind = SportKind.from_title(payload['name'])
        end

        save_title! unless @title.persisted?
      end

      def find_or_create_country!(payload)
        Rails.logger.debug "Country data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ['Country is missing, exiting', @payload]
          return
        end

        @country = EventScope.find_or_initialize_by(
          kind: :country,
          external_id: payload['id']
        ) do |country|
          country.title = @title
          country.name = payload['name']
        end

        save_country! unless @country.persisted?
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

      def save_title!
        @title.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn ["Title ID #{title_id} creating failed", e.message]
        @title = Title.find_by!(external_id: title_id)
      end

      def save_country!
        @country.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn ["Country ID #{title_id} creating failed", e.message]
        @country = EventScope.find_by!(external_id: country_id, kind: :country)
      end

      def title_id
        @payload['sport']['id']
      end

      def country_id
        @payload['category']['id']
      end
    end
  end
end
