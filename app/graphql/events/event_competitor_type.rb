module Events
  EventCompetitorType = GraphQL::ObjectType.define do
    name 'EventCompetitor'

    field :id, !types.ID
    field :name, !types.String
  end
end
