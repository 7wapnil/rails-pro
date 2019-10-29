module EveryMatrix
  SessionType = GraphQL::ObjectType.define do
    name 'Session'

    field :launchUrl, !types.String
  end
end
