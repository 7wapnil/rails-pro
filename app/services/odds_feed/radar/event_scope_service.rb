module OddsFeed
  module Radar
    class EventScopeService < ApplicationService
      SPORT_KIND_MAPPING = {
        'Alpine Skiing' => :sports,
        'American Football' => :sports,
        'Bandy' => :sports,
        'Badminton' => :sports,
        'Baseball' => :sports,
        'Basketball' => :sports,
        'CS:GO' => :esports,
        'Counter-Strike' => :esports,
        'Cricket' => :sports,
        'Cycling' => :sports,
        'Dota 2' => :esports,
        'Floorball' => :sports,
        'Futsal' => :sports,
        'Golf' => :sports,
        'Handball' => :sports,
        'Ice Hockey' => :sports,
        'League of Legends' => :esports,
        'Kabaddi' => :sports,
        'Motorsport' => :sports,
        'Rugby' => :sports,
        'Rink Hockey' => :sports,
        'Snooker' => :sports,
        'Snowboard' => :sports,
        'Soccer' => :sports,
        'Squash' => :sports,
        'Table Tennis' => :sports,
        'Tennis' => :sports,
        'Volleyball' => :sports,
        'Waterpolo' => :sports
      }.freeze
      def initialize(payload)
        @payload = payload
      end

      def call
        find_or_create_title!(@payload['sport'])
        find_or_create_tournament!(@payload)
        find_or_create_country!(@payload['category'])
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
          object.kind = SPORT_KIND_MAPPING[title['name']]
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
