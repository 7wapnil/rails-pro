module Graphql
  class Serializer
    class << self
      def dump(obj)
        dumped = GraphQL::Subscriptions::Serialize.send(:dump_value, obj)
        JSON.generate(dumped, quirks_mode: true)
      end

      def load(str)
        parsed_obj = JSON.parse(str)
        # TODO: Parse incoming value before deliver to detect profiler passed
        GraphQL::Subscriptions::Serialize.send(:load_value, parsed_obj)
      end
    end
  end
end
