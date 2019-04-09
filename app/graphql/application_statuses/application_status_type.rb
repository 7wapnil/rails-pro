module ApplicationStatuses
  ApplicationStatusType = GraphQL::ObjectType.define do
    name 'ApplicationStatus'

    field :status, types.String
  end
end
