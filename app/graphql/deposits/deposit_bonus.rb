module Deposits
  DepositBonus = GraphQL::ObjectType.define do
    name 'DepositBonus'

    field :realMoney, !types.Float, property: :real_money
    field :bonus, !types.Float
  end
end
