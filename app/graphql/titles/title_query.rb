# frozen_string_literal: true

module Titles
  class TitleQuery < ::Base::Resolver
    type !TitleType

    description 'Get title'

    argument :slug, types.String

    def auth_protected?
      false
    end

    def resolve(*, args)
      Title.find_by!(slug: args[:slug])
    end
  end
end
