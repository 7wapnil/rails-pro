module Events
  module BySport
    class SportFilter < ::Base::InputObject
      description 'Sports filtering attributes'

      argument :categoryId, ID, required: false
      argument :tournamentId, ID, required: false
    end
  end
end
