module Graphql
  class Serializer
    extend OddsFeed::FlowProfiler

    class << self
      def dump(obj)
        dumped = GraphQL::Subscriptions::Serialize.send(:dump_value, obj)
        JSON.generate(dumped, quirks_mode: true)
      end

      def load(str)
        parsed_obj = JSON.parse(str)
        loaded = GraphQL::Subscriptions::Serialize.send(:load_value, parsed_obj)

        if loaded&.has_key? :profiler
          create_flow_profiler(attributes: loaded[:profiler].to_h)
          flow_profiler.trace_profiler_event(:action_cable_prepares_delivery_at)
          return loaded[:data]
        end

        loaded
      end
    end
  end
end
