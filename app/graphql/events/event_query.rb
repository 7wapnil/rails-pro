module Events
  class EventQuery < ::Base::Resolver
    type EventType

    description 'Get single event by ID'

    argument :id, !types.ID

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Event.find_by(id: args[:id],
                    visible: true)
    end
  end
end
