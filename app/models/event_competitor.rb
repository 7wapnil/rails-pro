class EventCompetitor < ApplicationRecord
  include Importable

  enum qualifier: {
    home: 'home',
    away: 'away'
  }

  belongs_to :event
  belongs_to :competitor
end
