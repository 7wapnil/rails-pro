# frozen_string_literal: true

module OddsFeed
  module Radar
    class TitlesLoader < ApplicationService
      ROUTE = '/sports/en/sports.xml'
      ESPORTS_MAP = %w[
        sr:sport:107 sr:sport:76 sr:sport:164 sr:sport:158
        sr:sport:162 sr:sport:168 sr:sport:118 sr:sport:133
        sr:sport:109 sr:sport:123 :sport:111 sr:sport:154
        sr:sport:137 sr:sport:132 sr:sport:124 sr:sport:113
        sr:sport:114 sr:sport:134 sr:sport:110 sr:sport:167
        sr:sport:153 sr:sport:121 sr:sport:161 sr:sport:140
        sr:sport:166 sr:sport:139 sr:sport:125 sr:sport:128
        sr:sport:119 sr:sport:160 sr:sport:112 sr:sport:127
        sr:sport:156 sr:sport:159 sr:sport:120 sr:sport:122
        sr:sport:115 sr:sport:152
      ].freeze

      def call
        load_titles
      end

      private

      def load_titles
        payload['sports']['sport'].each { |params| create_title(params) }
      end

      def client
        @client ||= OddsFeed::Radar::Client.new
      end

      def payload
        @payload ||= client.request(ROUTE)
      end

      def create_title(params)
        Title.create_or_ignore_on_duplicate(
          name: params['name'],
          external_id: params['id'],
          kind: kind(params['id'])
        )
      end

      def kind(id)
        ESPORTS_MAP.include?(id) ? :esports : :sports
      end
    end
  end
end
