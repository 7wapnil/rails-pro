module OddsFeed
  module Radar
    class EventAdapter
      class TitleSelector < ApplicationService
        include JobLogger

        def initialize(payload: {})
          @id   = payload['id']
          @name = payload['name']
        end

        def call
          return found_title if found_title

          log_job_message(:info, 'Title was not found, creating new')

          create_title!
        rescue ActiveRecord::RecordInvalid
          log_job_message(:info, 'Title cannot be set, exiting')
        rescue ActiveRecord::RecordNotUnique
          log_job_message(
            :info, 'Title is not unique, trying to reload AR relation'
          )

          reload_and_find_title!
        end

        private

        attr_reader :id, :name

        def found_title
          @found_title ||= Title.find_by(search_params)
        end

        def reload_and_find_title!
          Title.all.reload.find_by!(search_params)
        end

        def search_params
          ['external_id = ? OR name = ?', id, name]
        end

        def create_title!
          Title.create!(kind: :sports, name: name, external_id: id)
        end
      end
    end
  end
end
