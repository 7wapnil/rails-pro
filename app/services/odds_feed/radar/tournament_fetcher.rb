module OddsFeed
  module Radar
    class TournamentFetcher < ApplicationService
      def call
        payload = api_client.tournaments
        payload['tournaments']['tournament'].each do |tournament|
          parse!(tournament)
        end
      end

      def parse!(tournament)
        find_or_create_title!(tournament['sport'])
        find_or_create_tournament!(tournament)
        find_or_create_country!(tournament['category'])
        find_or_create_season!(tournament['current_season'])
      end

      private

      def api_client
        @api_client ||= Client.new
      end

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
        end
      end

      def find_or_create_tournament!(tournament)
        Rails.logger.info "Tournament data received: #{tournament}"

        unless tournament
          Rails.logger.info 'Tournament is missing, exiting'
          return
        end

        @tournament = EventScope.find_or_create_by!(
          external_id: tournament['id'],
          title: @title
        ) do |event_scope|
          event_scope.name = tournament['name']
          event_scope.kind = :tournament
        end
      end

      def find_or_create_country!(country)
        Rails.logger.info "Country data received: #{country}"

        unless country
          Rails.logger.info 'Country is missing, exiting'
          return
        end

        @country = EventScope.find_or_create_by!(
          external_id: country['id'],
          title: @title,
          event_scope: @tournament
        ) do |event_scope|
          event_scope.name = country['name']
          event_scope.kind = :country
        end
      end

      def find_or_create_season!(season)
        Rails.logger.info "Season data received: #{season}"

        unless season
          Rails.logger.info 'Season is missing, exiting'
          return
        end

        @season = EventScope.find_or_create_by!(
          external_id: season['id'],
          event_scope: @country,
          title: @title
        ) do |event_scope|
          event_scope.name = season['name']
          event_scope.kind = :season
        end
      end
    end
  end
end
