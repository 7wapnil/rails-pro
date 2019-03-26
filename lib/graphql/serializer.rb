module Graphql
  class Serializer
    class << self
      def dump(obj)
        dumped = GraphQL::Subscriptions::Serialize.send(:dump_value, obj)
        JSON.generate(dumped, quirks_mode: true)
      end

      def load(str)
        parsed_obj = JSON.parse(str)
        loaded = GraphQL::Subscriptions::Serialize.send(:load_value, parsed_obj)
        is_profiled_message = loaded&.has_key? :profiler

        return load_profiled_data(loaded) if is_profiled_message

        loaded
      end

      private

      def load_profiled_data(loaded)
        return loaded[:data] unless loaded[:profiler]

        loaded[:profiler]&.log_state(:action_cable_prepares_delivery_at)
        loaded[:data]
      end
    end
  end
end
