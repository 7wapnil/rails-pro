class EventCompetitor < ApplicationRecord
  include Importable

  belongs_to :event
  belongs_to :competitor
end
