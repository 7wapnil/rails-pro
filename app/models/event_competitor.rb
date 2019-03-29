class EventCompetitor < ApplicationRecord
  belongs_to :event
  belongs_to :competitor
end
