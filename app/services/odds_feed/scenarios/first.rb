# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class First < Base
      private

      def scenario_path
        Rails.root.join('certification', 'scenario_1.csv')
      end
    end
  end
end
