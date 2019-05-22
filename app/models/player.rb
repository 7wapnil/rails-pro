class Player < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  validates :name, :external_id, presence: true

  def self.from_radar_payload(payload)
    params = payload.dig('player_profile', 'player')
    raise ArgumentError, 'Player payload is malformed' unless params

    new(
      external_id: params['id'],
      name: params['name'],
      full_name: params['full_name']
    )
  end
end
