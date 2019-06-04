module Account
  module VerifyPasswordToken
    ResponseType = GraphQL::ObjectType.define do
      name 'VerifyPasswordTokenResponseType'

      field :success, !types.Boolean
      field :message, !types.String
    end
  end
end
