# frozen_string_literal: true

module Account
  class CancelActiveBonus < ::Base::Resolver
    type !types.Boolean

    # mark_as_trackable

    description 'Customer Bonus customer cancellation service'

    def resolve(_obj, _args)
      form =
        CustomerBonuses::CancelActiveForm.new(
          current_customer: current_customer
        )
      form.submit!

      true
    end
  end
end
