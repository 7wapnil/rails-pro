# frozen_string_literal: true

module EveryMatrix
  class CategoriesQuery < ::Base::Resolver
    type !types[CategoryType]

    description 'List of casino games'

    argument :kind, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      browser = Browser.new(@request.user_agent)

      EveryMatrix::Category.where(
        kind: args['kind'],
        platform_type: platform_type(browser.device)
      )
    end

    def platform_type(device)
      return Category::MOBILE if device.mobile? || device.tablet?

      Category::DESKTOP
    end
  end
end
