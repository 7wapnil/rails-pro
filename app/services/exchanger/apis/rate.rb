module Exchanger
  module Apis
    class Rate
      attr_reader :code, :value

      def initialize(code, value)
        @code = code
        @value = value
      end
    end
  end
end
