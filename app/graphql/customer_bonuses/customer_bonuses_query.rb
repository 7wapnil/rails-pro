# frozen_string_literal: true

module CustomerBonuses
  class CustomerBonusesQuery < ::Base::Resolver
    type types[CustomerBonuses::CustomerBonusType]
    decorate_with CustomerBonusDecorator

    def resolve(_obj, _args)
      CustomerBonus
        .customer_history(current_customer)
        .where.not(status: CustomerBonus::SYSTEM_STATUSES)
        .order(activated_at: :desc)
    end
  end
end
