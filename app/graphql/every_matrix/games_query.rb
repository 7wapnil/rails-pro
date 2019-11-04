# frozen_string_literal: true

module EveryMatrix
  class GamesQuery < ::Base::Resolver
    type !types[PlayItemType]

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      browser = Browser.new(@request.user_agent)

      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Game,
        category: args['context'],
        device: browser.device
      )
    end
  end
end
