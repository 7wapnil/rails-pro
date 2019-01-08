# frozen_string_literal: true

class Title < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  has_many :events, dependent: :destroy
  has_many :event_scopes, dependent: :destroy
  has_many :tournaments, -> { where kind: EventScope::TOURNAMENT },
           class_name: 'EventScope'

  enum kind: {
    esports: ESPORTS = 'esports',
    sports:  SPORTS  = 'sports'
  }

  validates :name, :kind, presence: true
  validates :name, uniqueness: true

  scope :with_active_events, -> {
    eager_load(:events).where(events: { active: true })
  }
end
