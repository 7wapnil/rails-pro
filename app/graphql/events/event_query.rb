# frozen_string_literal: true

module Events
  class EventQuery < ::Base::Resolver
    type !EventType

    description 'Get single event by slug'

    argument :slug, types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Event.visible.find_by!(slug: args[:slug])
    end
  end
end
