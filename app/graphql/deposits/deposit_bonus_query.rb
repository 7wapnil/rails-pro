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
      bonus = find_bonus!(args)
      form = CustomerBonuses::CreateForm.new(customer: current_customer,
                                             original_bonus: bonus)
      form.validate!
      bonus_hash = BalanceCalculations::Deposit.call(args[:amount], bonus)
      CalculatedBonus.new(bonus_hash)
    end

    private

    def find_bonus!(args)
      bonus = Bonus.from_code(args[:code])
      return bonus if bonus

      message = format(I18n.t('not_found'), instance: 'bonus')
      raise ActiveRecord::RecordNotFound.new, message
    end
  end
end
