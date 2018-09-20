module Events
  class EventFilter < Base::InputObject
    description 'Events filtering attributes'

    argument :titleId, ID, required: false
    argument :inPlay, Boolean, required: false
  end
end
