# frozen_string_literal: true

module GraphqlExtensions
  module Subscriptions
    module Serializer
      extend OddsFeed::FlowProfiler

      class << self
        def load(json_string)
          object = JSON.parse(json_string)

          return load_open_struct(object) if open_struct_loaded?(object)
          return load_profiled_hash(json_string) if profiled_hash?(object)

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

        def profiled_hash?(parsed_object)
          parsed_object.is_a?(Hash) &&
            parsed_object['profiler'].present?
        end

        def load_profiled_hash(json_string)
          loaded_object = GraphQL::Subscriptions::Serialize.load(json_string)
          handle_profiled_data(loaded_object[:profiler])
          loaded_object[:data]
        end

        def load_open_struct(parsed_object)
          handle_profiled_data(parsed_object.delete('profiler'))
          OpenStruct.new(parsed_object.except('open_struct'))
        end

        def handle_profiled_data(profiler_attributes)
          return unless profiler_attributes

          create_flow_profiler(attributes: profiler_attributes.to_h)
          flow_profiler.trace_profiler_event(:action_cable_prepares_delivery_at)
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
