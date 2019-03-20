# frozen_string_literal: true

class ScopedEvent < ApplicationRecord
  include Importable

  conflict_target :event_id, :event_scope_id
  conflict_updatable :updated_at

  belongs_to :event_scope
  belongs_to :event

  validates :event_scope_id, uniqueness: { scope: :event_id }
end
