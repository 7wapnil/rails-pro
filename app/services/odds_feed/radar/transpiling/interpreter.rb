module OddsFeed
  module Radar
    module Transpiling
      class Interpreter
        include JobLogger

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
            regex: /^\%/,
            expression: NameExpression
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
          rescue StandardError => e
            log_parsing_error(e)
          end
          log_parsing_success(template, result)

          result
        end

        def token_value(token)
          match = MATCHERS.detect { |rule| token =~ rule[:regex] }
          expression_class = match.nil? ? SimpleExpression : match[:expression]
          result = expression_class
                   .new(self)
                   .value(token)
                   .to_s

          log_job_message(:debug,
                          message: 'Token transpiled',
                          token: token,
                          result: result,
                          event_id: event.id)
          result
        end

        def log_parsing_error(error)
          log_job_message(:warn,
                          message: 'Interpreter error',
                          description: error.message,
                          event_id: event.id)
        end

        def log_parsing_success(template, result)
          log_job_message(:debug,
                          message: 'Template transpiled',
                          template: template,
                          result: result,
                          event_id: event.id)
        end
      end
    end
  end
end
