class CompetitorPlayer < ApplicationRecord
  include Importable

  belongs_to :competitor
  belongs_to :player
end
