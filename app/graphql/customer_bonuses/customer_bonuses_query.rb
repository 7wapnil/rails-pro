# frozen_string_literal: true

module CustomerBonuses
  class CustomerBonusesQuery < ::Base::Resolver
    type CustomerBonuses::CustomerBonusType

    def resolve(_obj, _args)
      current_customer.customer_bonus
    end
  end
end
