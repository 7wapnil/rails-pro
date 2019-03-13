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
      bonus = find_bonus(args)
      bonus_hash = BalanceCalculations::Deposit.call(bonus, args[:amount])
      CalculatedBonus.new(bonus_hash)
    end

    private

    def find_bonus(args)
      model = Bonus.active.find_by(code: args[:code])

      unless model
        message = I18n.t('not_found') % { instance: 'bonus' }
        raise ActiveRecord::RecordNotFound.new(message)
      end
      model
    end
  end
end
