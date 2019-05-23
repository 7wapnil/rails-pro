# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class Second < Base
      private

      def scenario_path
        Rails.root.join('certification', 'scenario_2.csv')
      end
    end
  end
end
