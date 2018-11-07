module OddsFeed
  module Radar
    class EventScopeService < ApplicationService
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

      def find_or_create_tournament!(payload)
        Rails.logger.debug "Tournament data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ['Tournament is missing, exiting', @payload]
          return
        end

        @tournament = EventScope.find_or_initialize_by(
          kind: :tournament,
          external_id: payload['id']
        ) do |tournament|
          tournament.title = @title
          tournament.event_scope = @country
          tournament.name = payload['name']
        end

        save_tournament! unless @tournament.persisted?
      end

      def find_or_create_season!(payload)
        Rails.logger.debug "Season data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ['Season is missing, exiting', @payload]
          return
        end

        @season = EventScope.find_or_initialize_by(
          kind: :season,
          external_id: payload['id']
        ) do |season|
          season.title = @title
          season.event_scope = @tournament
          season.name = payload['name']
        end

        save_season! unless @season.persisted?
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
        Rails.logger.warn ["Country ID #{country_id} creating failed", e.message]

        @country = EventScope.find_by!(external_id: country_id, kind: :country)
      end

      def save_tournament!
        @tournament.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn [
          "Tournament ID #{tournament_id} creating failed",
          e.message
        ]

        @tournament = EventScope.find_by!(
          external_id: tournament_id,
          kind: :tournament
        )
      end

      def save_season!
        @season.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn ["Season ID #{season_id} creating failed", e.message]

        @season = EventScope.find_by!(external_id: season_id, kind: :season)
      end

      def title_id
        @payload['sport']['id']
      end

      def country_id
        @payload['category']['id']
      end

      def tournament_id
        @payload['id']
      end

      def season_id
        @payload['current_season']['id']
      end
    end
  end
end
