module Events
  module BySport
    class EsportFilter < ::Base::InputObject
      description 'Esports filtering attributes'

      argument :titleId, ID, required: false
      argument :categoryId, ID, required: false
      argument :tournamentId, ID, required: false
    end
  end
end
