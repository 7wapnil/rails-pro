module Base
  module Offsetable
    extend ::ActiveSupport::Concern

    included do
      argument :offset, types.Int, 'Result offset', default_value: 0
    end
  end
end
