# frozen_string_literal: true

module CustomerBonuses
  class BonusesQuery < ::Base::Resolver
    type types[CustomerBonuses::BonusType]
    decorate_with CustomerBonusDecorator
    mark_as_trackable

    def resolve(_obj, _args)
      CustomerBonus
        .customer_history(current_customer)
        .where.not(status: CustomerBonus::SYSTEM_STATUSES)
        .order(activated_at: :desc)
    end
  end
end
