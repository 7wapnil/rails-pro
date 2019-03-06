module Deposits
  class CalculatedBonus
    attr_reader :real_money, :bonus

    def initialize(args)
      @real_money = args[:real_money]
      @bonus = args[:bonus]
    end
  end

  class DepositBonusQuery < ::Base::Resolver
    type DepositBonus

    description 'Get deposit bonus calculation'

    argument :amount, !types.Float
    argument :code, !types.String

    def resolve(_obj, args)
      bonus = Bonus.find_by!(code: args[:code])
      bonus_hash = BalanceCalculations::Deposit.call(bonus, args[:amount])
      CalculatedBonus.new(bonus_hash)
    end
  end
end
