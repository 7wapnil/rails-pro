module Events
  class EventFilter < Base::InputObject
    description 'Events filtering attributes'

    argument :id, ID, required: false
    argument :titleId, ID, required: false
    argument :tournamentId, ID, required: false
    argument :inPlay, Boolean, required: false
    argument :upcoming, Boolean, required: false
  end
end
