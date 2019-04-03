module EventsManager
  module Entities
    class BaseEntity
      def initialize(payload)
        @payload = payload
      end

      def to_s
        @payload.to_s
      end

      def attribute(source, *args)
        source.dig(*args)
      end

      def attribute!(source, *args)
        raise StandardError, 'Source is malformed' unless source

        result = attribute(source, *args)
        err_msg = "Payload is malformed, searching: #{args.join(', ')}"
        raise StandardError, err_msg if result.nil?

        result
      end

      protected

      def ensure_array(value)
        return [] unless value

        Array[value].compact.flatten
      end
    end
  end
end
