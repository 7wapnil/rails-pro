# frozen_string_literal: true

module Events
  class EventQuery < ::Base::Resolver
    type !EventType

    description 'Get single event by slug or id'

    argument :slug, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Event.friendly.visible.find(args[:slug])
    end
  end
end
