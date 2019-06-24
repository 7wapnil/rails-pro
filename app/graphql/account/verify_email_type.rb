module Account
  VerifyEmailType = GraphQL::ObjectType.define do
    name 'VerifyEmail'

    field :success, !types.Boolean
    field :userID, !types.ID,
          property: :user_id
  end
end
