# frozen_string_literal: true

module Account
  class UpdateUser < ::Base::Resolver
    argument :input, !Account::UpdateUserInput

    type Account::UserType
    mark_as_trackable

    description 'Update customer\' fields'

    def resolve(_obj, args)
      ::Customers::UpdateForm.new(
        subject: @current_customer,
        first_name: args[:input][:firstName],
        last_name: args[:input][:lastName],
        city: args[:input][:city],
        street_address: args[:input][:streetAddress],
        phone: args[:input][:phone]
      ).submit!
    end
  end
end
