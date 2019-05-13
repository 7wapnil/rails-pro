# frozen_string_literal: true

module CustomerBonuses
  class CustomerBonusesQuery < ::Base::Resolver
    type types[CustomerBonuses::CustomerBonusType]

    def resolve(_obj, _args)
      CustomerBonus.customer_history(current_customer)
    end
  end
end
