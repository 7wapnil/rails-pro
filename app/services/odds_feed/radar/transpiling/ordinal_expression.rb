module OddsFeed
  module Radar
    module Transpiling
      class OrdinalExpression < BaseExpression
        def value(token)
          number = extract_number(token).to_i
          "#{number}#{number.ordinal}"
        end

        private

        def extract_number(token)
          number_part = token[1..-1]
          return number_part if numeric?(number_part)

          specifier(number_part)
        end

        def numeric?(value)
          !Float(value).nil?
        rescue StandardError
          false
        end
      end
    end
  end
end
