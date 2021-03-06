# frozen_string_literal: true

module Deposits
  class DepositBonusQuery < ::Base::Resolver
    type DepositBonus
    mark_as_trackable

    description 'Get deposit bonus calculation'

    argument :amount, !types.Float
    argument :code, !types.String
    argument :currencyCode, !types.String

    def resolve(_obj, args)
      bonus = find_bonus!(args)
      currency = find_currency!(args)
      form = CustomerBonuses::CreateForm.new(customer: current_customer,
                                             original_bonus: bonus,
                                             amount: args[:amount],
                                             currency: currency)
      form.validate!
      bonus_hash = BalanceCalculations::Deposit.call(
        args[:amount],
        currency,
        bonus
      )
      Deposits::CalculatedBonus.new(bonus_hash)
    end

    private

    def find_bonus!(args)
      Bonus.from_code(args[:code])
    end

    def find_currency!(args)
      Currency.find_by!(code: args[:currencyCode])
    end
  end
end
