module Deposits
  DepositBonus = GraphQL::ObjectType.define do
    name 'DepositBonus'

    field :real_money, !types.Float
    field :bonus, !types.Float
  end
end
