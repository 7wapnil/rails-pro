# frozen_string_literal: true

module Base
  module Pagination
    PaginatedObject = Struct.new(:pagination, :data)
  end
end
