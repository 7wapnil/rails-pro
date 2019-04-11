# frozen_string_literal: true

module Mts
  ConnectionStatusType = GraphQL::ObjectType.define do
    name 'MtsConnectionStatus'

    field :status, !types.String
  end
end
