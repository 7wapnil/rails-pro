# frozen_string_literal: true

module Types
  PaginationType = GraphQL::ObjectType.define do
    name 'Pagination'

    field :count, types.Int
    field :items, types.Int
    field :page, types.Int
    field :pages, types.Int
    field :offset, types.Int
    field :last, types.Int
    field :next, types.Int
    field :prev, types.Int
    field :from, types.Int
    field :to, types.Int
  end
end
