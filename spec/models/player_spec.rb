describe Player do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }

  describe '.from_radar_payload' do
    it 'raises an argument error' do
      payload = {
        'player_profile' => {
          'id' => 'sr:player:903786',
          'name' => 'Pezzella, Giuseppe',
          'full_name' => 'Giuseppe Pezzella',
          'type' => 'defender',
          'date_of_birth' => '1997-11-29',
          'nationality' => 'Italy',
          'country_code' => 'ITA',
          'height' => '187',
          'weight' => '85',
          'gender' => 'male'
        }
      }

      expect { described_class.from_radar_payload(payload) }
        .to raise_error ArgumentError, 'Player payload is malformed'
    end

    it 'returns an initialized player with correct attributes' do
      payload = {
        'player_profile' => {
          'player' => {
            'id' => 'sr:player:903786',
            'name' => 'Pezzella, Giuseppe',
            'full_name' => 'Giuseppe Pezzella',
            'type' => 'defender',
            'date_of_birth' => '1997-11-29',
            'nationality' => 'Italy',
            'country_code' => 'ITA',
            'height' => '187',
            'weight' => '85',
            'gender' => 'male'
          }
        }
      }

      player = described_class.from_radar_payload(payload)

      expected_attributes = {
        'external_id' => 'sr:player:903786',
        'name' => 'Pezzella, Giuseppe',
        'full_name' => 'Giuseppe Pezzella'
      }

      expect(player.attributes.slice(*expected_attributes.keys))
        .to eq expected_attributes
    end
  end
end
