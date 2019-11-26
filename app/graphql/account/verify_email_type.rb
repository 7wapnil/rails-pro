# frozen_string_literal: true

module Account
  VerifyEmailType = GraphQL::ObjectType.define do
    name 'VerifyEmail'

    field :success, !types.Boolean
    field :userId, !types.ID, property: :user_id
  end
end
