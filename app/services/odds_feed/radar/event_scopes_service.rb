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

        @title = Title.find_or_initialize_by(external_id: title_id) do |title|
          title.name = payload['name']
          title.kind = SportKind.from_title(payload['name'])
        end

        save_title! unless @title.persisted?
      end

      def find_or_create_country!(payload)
        return unless payload_valid_for?('Country', payload)

        @country = EventScope.find_or_initialize_by(
          kind: :country,
          external_id: payload['id']
        ) do |country|
          country.title = @title
          country.name = payload['name']
        end

        save_scope!(:country) unless @country.persisted?
      end

      def find_or_create_tournament!(payload)
        return unless payload_valid_for?('Tournament', payload)

        @tournament = EventScope.find_or_initialize_by(
          kind: :tournament,
          external_id: payload['id']
        ) do |tournament|
          tournament.title = @title
          tournament.event_scope = @country
          tournament.name = payload['name']
        end

        save_scope!(:tournament) unless @tournament.persisted?
      end

      def find_or_create_season!(payload)
        return unless payload_valid_for?('Season', payload)

        @season = EventScope.find_or_initialize_by(
          kind: :season,
          external_id: payload['id']
        ) do |season|
          season.title = @title
          season.event_scope = @tournament
          season.name = payload['name']
        end

        save_scope!(:season) unless @season.persisted?
      end

      def payload_valid_for?(scope, payload)
        Rails.logger.debug "#{scope} data received: #{payload}"

        unless payload.is_a?(Hash)
          Rails.logger.warn ["#{scope} is missing, exiting", @payload]
          return false
        end

        true
      end

      def save_scope!(kind)
        send(kind).save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        instance_variable_set("@#{kind}", nil)

        scope_id = scope_id(kind)
        Rails.logger.warn ["#{kind} ID #{scope_id} creating failed", e.message]

        scope = EventScope.find_by!(external_id: scope_id, kind: kind)
        instance_variable_set("@#{kind}", scope)
      end

      def save_title!
        @title.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn ["Title ID #{title_id} creating failed", e.message]

        @title = Title.find_by!(external_id: title_id)
      end

      def scope_id(kind)
        case kind
        when :country
          @payload['category']['id']
        when :tournament
          @payload['id']
        when :season
          @payload['current_season']['id']
        end
      end

      def title_id
        @payload['sport']['id']
      end
    end
  end
end
