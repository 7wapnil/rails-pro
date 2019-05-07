module OddsFeed
  module Radar
    module Transpiling
      class CombinedExpression < BaseExpression
        include JobLogger

        def value(token)
          token = token.tr('(', '{').tr(')', '}')
          result = @interpreter.parse(token)
          @interpreter.token_value(result)
        end

        private

        def internal_expression(token)
          internal = token.match(/\(([^\)]*)/)
          return internal[1] if internal.length == 2

          log_job_message(:warn, message: 'Unable to parse token',
                                 token: token)
          raise 'Unknown token'
        end
      end
    end
  end
end
