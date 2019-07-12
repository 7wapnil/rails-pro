# frozen_string_literal: true

class EventCompetitor < ApplicationRecord
  include Importable

  enum qualifier: {
    home: HOME = 'home',
    away: AWAY = 'away'
  }

  belongs_to :event
  belongs_to :competitor

  delegate :name, :external_id, to: :competitor
end
