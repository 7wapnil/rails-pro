module Titles
  TitleType = GraphQL::ObjectType.define do
    name 'Title'

    field :id, !types.ID
    field :name, !types.String
    field :kind, !types.String
  end
end