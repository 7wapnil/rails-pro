# frozen_string_literal: true

Events::ContextType = GraphQL::ObjectType.define do
  name 'EventContext'

  field :context, Events::ContextEnum
  field :show, !types.Boolean
end
