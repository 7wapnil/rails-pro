# frozen_string_literal: true

module Customers
  module Summaries
    class UpdateWorker < ApplicationWorker
      def perform(day, attributes)
        Customers::Summaries::Updater.call(day, attributes)
      end
    end
  end
end
