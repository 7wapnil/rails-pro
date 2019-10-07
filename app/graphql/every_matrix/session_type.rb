module EveryMatrix
  SessionType = GraphQL::ObjectType.define do
    name 'Session'

    field :sessionId, !types.String
  end
end
