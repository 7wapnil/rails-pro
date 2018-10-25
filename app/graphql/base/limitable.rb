module Base
  module Limitable
    extend ::ActiveSupport::Concern

    included do
      argument :limit, types.Int, 'Result limit', default_value: 5
    end
  end
end
