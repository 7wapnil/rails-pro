# frozen_string_literal: true

module Payments
  module Methods
    SkrillType = GraphQL::ObjectType.define do
      name 'PaymentMethodSkrill'

      field :id, !types.ID
      field :title, !types.String, property: :email
      field :email, !types.String
    end
  end
end
