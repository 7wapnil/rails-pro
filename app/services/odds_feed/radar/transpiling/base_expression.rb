module OddsFeed
  module Radar
    module Transpiling
      class BaseExpression
        def initialize(interpreter)
          @interpreter = interpreter
        end

        def value(_token)
          raise NotImplementedError
        end

        def event
          @interpreter.event
        end

        def specifiers_map
          @interpreter.specifiers_map
        end

        def specifier(name)
          raise "Specifier '#{name}' not found" if specifiers_map[name].nil?

          specifiers_map[name]
        end
      end
    end
  end
end
