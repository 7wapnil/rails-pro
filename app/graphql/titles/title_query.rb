module Titles
  class TitleQuery < ::Base::Resolver
    type TitleType

    description 'Get title by ID'

    argument :id, !types.ID

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Title.find_by(id: args[:id])
    end
  end
end
