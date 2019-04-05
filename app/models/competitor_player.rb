class CompetitorPlayer < ApplicationRecord
  belongs_to :competitor
  belongs_to :player
end
