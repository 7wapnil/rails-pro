# frozen_string_literal: true

module GraphqlExtensions
  module Subscriptions
    module Serializer
      class << self
        def load(json_string)
          object = JSON.parse(json_string)

          return load_open_struct(object) if open_struct_loaded?(object)

          GraphQL::Subscriptions::Serialize.load(json_string)
        end

        def dump(object)
          return dump_open_struct(object) if object.is_a?(OpenStruct)

          GraphQL::Subscriptions::Serialize.dump(object)
        end

        private

        def open_struct_loaded?(parsed_object)
          parsed_object.is_a?(Hash) &&
            parsed_object['open_struct'].present?
        end

        def load_open_struct(parsed_object)
          OpenStruct.new(parsed_object.except('open_struct'))
        end

        def dump_open_struct(object)
          JSON.generate(
            object.to_h.merge(open_struct: true),
            quirks_mode: true
          )
        end
      end
    end
  end
end
