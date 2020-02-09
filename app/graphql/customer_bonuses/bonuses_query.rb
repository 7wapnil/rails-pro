# frozen_string_literal: true

module CustomerBonuses
  class BonusesQuery < ::Base::Resolver
    type types[CustomerBonuses::BonusType]
    decorate_with CustomerBonusDecorator
    mark_as_trackable

    argument :status, types.String

    def resolve(_obj, args)
      bonuses = CustomerBonus
                .customer_history(current_customer)
                .where.not(status: CustomerBonus::SYSTEM_STATUSES)
                .order(activated_at: :desc)

      args.status.present? ? bonuses.where(status: args.status) : bonuses
    end
  end
end
