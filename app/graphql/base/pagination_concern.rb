module Base
  module PaginationConcern
    extend ::ActiveSupport::Concern

    included do
      argument :offset, types.Int, 'Result offset', default_value: 0
      argument :limit, types.Int, 'Result limit'
    end
  end
end
