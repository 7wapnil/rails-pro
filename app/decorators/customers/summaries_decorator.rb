# frozen_string_literal: true

module Customers
  class SummariesDecorator < PaginationDecorator
    include Customers::Summaries::DerivedMethods

    EXCLUDE_REDUCE = %w[id day create_at updated_at].freeze

    (Customers::Summary.column_names - EXCLUDE_REDUCE).each do |column|
      define_method column do
        object.pluck(column).reduce(:+)
      end
    end
  end
end
