# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class Third < Base
      private

      def scenario_path
        Rails.root.join('certification', 'scenario_3.json')
      end
    end
  end
end
