module Events
  EventCompetitorType = GraphQL::ObjectType.define do
    name 'EventCompetitor'

    field :id, !types.ID do
      resolve ->(obj, *) { "#{obj.event_id}-#{obj.competitor_id}" }
    end

    field :name, !types.String
    field :qualifier, !types.String
  end
end
