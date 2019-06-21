# frozen_string_literal: true

module Customers
  class SummaryDecorator < ApplicationDecorator
    include Customers::Summaries::DerivedMethods

    def self.collection_decorator_class
      SummariesDecorator
    end
  end
end
