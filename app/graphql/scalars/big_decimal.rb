module Scalars
  BigDecimal = GraphQL::ScalarType.define do
    name 'BigDecimal'
    description 'Big decimal number scalar type'

    coerce_input ->(value, _ctx) { BigDecimal(value, 8) }
    coerce_result ->(value, _ctx) { value.to_f }
  end
end
