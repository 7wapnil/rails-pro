describe OddsFeed::Radar::PlayerLoader do
  describe '.call' do
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

      allow_any_instance_of(OddsFeed::Radar::Client)
        .to receive(:player_profile)
        .with('sr:player:903786')
        .and_return(payload)

      expect { described_class.call('sr:player:903786') }
        .to raise_error ArgumentError, 'Player payload is malformed'
    end

    it 'returns an initialized plauer with correct attributes' do
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

      allow_any_instance_of(OddsFeed::Radar::Client)
        .to receive(:player_profile)
        .with('sr:player:903786')
        .and_return(payload)

      player = described_class.call('sr:player:903786')

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
