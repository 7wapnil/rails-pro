module Base
  module Limitable
    extend ::ActiveSupport::Concern

    included do
      argument :limit, types.Int, 'Result limit'
    end
  end
end
