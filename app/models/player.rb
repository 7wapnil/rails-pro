# frozen_string_literal: true

class Player < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  validates :name, :external_id, presence: true
end
