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
        return load_profiled_data(loaded) if loaded&.has_key? :profiler

        loaded
      end

      private

      def load_profiled_data(loaded)
        loaded[:profiler].log!
        loaded[:data]
      end
    end
  end
end
