module OddsFeed
  module Radar
    class EventAdapter
      class TitleSelector < ApplicationService
        def initialize(payload: {})
          @id   = payload['id']
          @name = payload['name']
        end

        def call
          return found_title if found_title

          Rails.logger.info 'Title was not found, creating new'

          create_title!
        end

        private

        attr_reader :id, :name

        def found_title
          @found_title ||= Title.find_by(
            'external_id = ? OR name = ?', id, name
          )
        end

        def create_title!
          Title.create!(kind: :sports, name: name, external_id: id)
        end
      end
    end
  end
end
