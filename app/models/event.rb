class Event < ApplicationRecord
  belongs_to :discipline
  belongs_to :event
  has_many :markets
end
