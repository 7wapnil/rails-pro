# frozen_string_literal: true

module GraphqlExtensions
  module Subscriptions
    module Serializer
      KEYWORDS = [
        OPEN_STRUCT = 'open_struct',
        DECORATED = 'decorated'
      ].freeze

      class << self
        def load(json_string)
          serialized_data = JSON.parse(json_string)
          keywords = extract_keywords!(serialized_data)

          return OpenStruct.new(serialized_data) if keywords[OPEN_STRUCT]

          original_json = dump_json(serialized_data)
          object = GraphQL::Subscriptions::Serialize.load(original_json)

          return object.decorate if keywords[DECORATED]

          object
        end

        def dump(object)
          return dump_open_struct(object) if object.is_a?(OpenStruct)

          serialized_data = GraphQL::Subscriptions::Serialize.dump(object)

          return dump_decorator(serialized_data) if object.try(:decorated?)

          serialized_data
        end

        private

        def extract_keywords!(serialized_data)
          return {} unless serialized_data.is_a?(Hash)

          keywords = serialized_data.slice(*KEYWORDS)

          serialized_data.except!(*KEYWORDS)

          keywords
        end

        def dump_open_struct(serialized_data)
          dump_json(
            serialized_data.to_h.merge(open_struct: true)
          )
        end

        def dump_json(serialized_data)
          JSON.generate(serialized_data, quirks_mode: true)
        end

        def dump_decorator(serialized_data)
          dump_json(
            JSON.parse(serialized_data).merge(decorated: true)
          )
        end
      end
    end
  end
end
