# frozen_string_literal: true

module Events
  class EventScopeQuery < ::Base::Resolver
    type !Types::EventScopeType

    description 'Get single event scope'

    argument :slug, types.String
    argument :kind, EventScopes::KindEnum

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      EventScope.find_by!(slug: args[:slug], kind: args[:kind])
    end
  end
end
