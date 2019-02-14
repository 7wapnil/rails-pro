# frozen_string_literal: true

module Base
  module Pagination
    Info = Struct.new(
      :count,
      :items,
      :page,
      :pages,
      :offset,
      :last,
      :next,
      :prev,
      :from,
      :to
    )
  end
end
