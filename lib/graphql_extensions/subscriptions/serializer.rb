# frozen_string_literal: true

module GraphqlExtensions
  module Subscriptions
    module Serializer
      class << self
        def load(json_string)
          data = JSON.parse(json_string)

          return load_open_struct(data) if open_struct_loaded?(data)

          object = GraphQL::Subscriptions::Serialize.load(json_string)

          return object.decorate if decorator_loaded?(data)

          object
        end

        def dump(object)
          return dump_open_struct(object) if object.is_a?(OpenStruct)

          serialized_data = GraphQL::Subscriptions::Serialize.dump(object)

          return dump_decorator(serialized_data) if object.try(:decorated?)

          serialized_data
        end

        private

        def open_struct_loaded?(serialized_data)
          serialized_data.is_a?(Hash) &&
            serialized_data['open_struct'].present?
        end

        def decorator_loaded?(serialized_data)
          serialized_data.is_a?(Hash) &&
            serialized_data['decorated'].present?
        end

        def load_open_struct(serialized_data)
          OpenStruct.new(serialized_data.except('open_struct'))
        end

        def dump_open_struct(serialized_data)
          JSON.generate(
            serialized_data.to_h.merge(open_struct: true),
            quirks_mode: true
          )
        end

        def dump_decorator(serialized_data)
          JSON.generate(
            JSON.parse(serialized_data).merge(decorated: true),
            quirks_mode: true
          )
        end
      end
    end
  end
end
