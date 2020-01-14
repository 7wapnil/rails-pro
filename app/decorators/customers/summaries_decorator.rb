# frozen_string_literal: true

module Customers
  class SummariesDecorator < PaginationDecorator
    include Customers::Summaries::DerivedMethods

    Customers::Summary::REDUCE_COLUMNS.each do |column|
      define_method column do
        object.map(&:"#{column}").reduce(:+)
      end
    end
  end
end
