# frozen_string_literal: true

module Base
  module Pagination
    PaginatedObject = Struct.new(:pagination, :collection)
  end
end
