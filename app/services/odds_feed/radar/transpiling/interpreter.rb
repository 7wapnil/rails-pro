module OddsFeed
  module Radar
    module Transpiling
      class Interpreter
        attr_reader :event, :specifiers_map

        MATCHERS = [
          {
            regex: /\(.*\)/,
            expression: CombinedExpression
          },
          {
            regex: /^\$/,
            expression: VariableExpression
          },
          {
            regex: /^\!/,
            expression: OrdinalExpression
          },
          {
            regex: /^(\-|\+)/,
            expression: SignedExpression
          },
          {
            regex: /.*\-|\+\d+/,
            expression: MathExpression
          }
        ].freeze

        def initialize(event, specifiers_map = {})
          @event = event
          @specifiers_map = specifiers_map
        end

        def parse(template)
          result = template
          template.scan(/\{([^\}]*)/).each do |matches|
            token = matches.first
            result = result.gsub("{#{token}}", token_value(token))
          rescue StandardError => error
            Rails.logger.warn error
          end
          result
        end

        def token_value(token)
          match = MATCHERS.detect { |rule| token =~ rule[:regex] }
          expression_class = match.nil? ? SimpleExpression : match[:expression]
          expression_class
            .new(self)
            .value(token)
            .to_s
        end
      end
    end
  end
end