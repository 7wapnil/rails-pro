describe OddsFeed::Radar::TournamentFetcher do
  let(:data) do
    XmlParser.parse(
      file_fixture('tournaments_response.xml').read
    )['tournaments']['tournament']
  end

  subject { OddsFeed::Radar::TournamentFetcher.new }

  context '.parse!' do
    let(:title_external_id) { data['sport']['id'] }
    let(:title_name) { data['sport']['name'] }

    let(:tournament_external_id) { data['id'] }
    let(:tournament_name) { data['name'] }

    let(:country_external_id) { data['category']['id'] }
    let(:country_name) { data['category']['name'] }

    let(:season_external_id) { data['current_season']['id'] }
    let(:season_name) { data['current_season']['name'] }

    before do
      subject.parse!(data)
    end

    it 'creates title without kind' do
      title = Title.find_by(external_id: title_external_id)
      expect(title).is_a? Title
      expect(title.name).to eq(title_name)
      expect(title.kind).to eq(nil)
    end

    it 'creates tournament' do
      title = Title.find_by(external_id: title_external_id)
      tournament = EventScope.find_by(
        external_id: tournament_external_id
      )
      expect(tournament).is_a? EventScope
      expect(tournament.name).to eq(tournament_name)
      expect(tournament.title).to eq(title)
      expect(tournament.kind).to eq('tournament')
    end

    it 'creates country' do
      title = Title.find_by(external_id: title_external_id)
      tournament = EventScope.find_by(
        external_id: tournament_external_id
      )
      country = EventScope.find_by(
        external_id: country_external_id
      )
      expect(country).is_a? EventScope
      expect(country.name).to eq(country_name)
      expect(country.title).to eq(title)
      expect(country.event_scope).to eq(tournament)
      expect(country.kind).to eq('country')
    end

    it 'creates season' do
      title = Title.find_by(external_id: title_external_id)
      country = EventScope.find_by(
        external_id: country_external_id
      )
      season = EventScope.find_by(
        external_id: season_external_id
      )
      expect(season).is_a? EventScope
      expect(season.name).to eq(season_name)
      expect(season.title).to eq(title)
      expect(season.event_scope).to eq(country)
      expect(season.kind).to eq('season')
    end
  end
end
