module Events
  EventCompetitorType = GraphQL::ObjectType.define do
    name 'EventCompetitor'

    field :id, !types.ID, property: :external_id
    field :name, !types.String
    field :qualifier, !types.String
  end
end
