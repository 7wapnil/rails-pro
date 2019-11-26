# frozen_string_literal: true

module Account
  UpdateUserInput = GraphQL::InputObjectType.define do
    name 'UpdateUserInput'

    argument :firstName, !types.String
    argument :lastName, !types.String
    argument :city, !types.String
    argument :streetAddress, !types.String
    argument :phone, !types.String
  end
end
