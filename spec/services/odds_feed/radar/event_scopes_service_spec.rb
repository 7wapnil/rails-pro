describe OddsFeed::Radar::EventScopesService do
  let(:payload) do
    XmlParser.parse(
      file_fixture('tournaments_response.xml').read
    )['tournaments']['tournament'][0]
  end

  subject(:service) { described_class.new(payload) }

  describe 'title' do
    it 'creates new from payload' do
      service.call
      created = Title.find_by(external_id: payload['sport']['id'])
      expect(created).not_to be_nil
    end

    it 'updates from payload if exists' do
      existing = create(:title,
                        external_id: payload['sport']['id'],
                        name: 'Old name')
      service.call

      existing.reload
      expect(existing.name).to eq(payload['sport']['name'])
    end
  end

  describe 'country' do
    it 'creates new from payload' do
      service.call
      created = EventScope.find_by(external_id: payload['category']['id'])
      expect(created).not_to be_nil
    end

    it 'updates from payload if exists' do
      existing = create(:event_scope,
                        external_id: payload['category']['id'],
                        kind: EventScope::COUNTRY,
                        name: 'Old name')
      service.call

      existing.reload
      expect(existing.name).to eq(payload['category']['name'])
    end
  end

  describe 'tournament' do
    it 'creates new from payload' do
      service.call
      created = EventScope.find_by(external_id: payload['id'])
      expect(created).not_to be_nil
    end

    it 'updates from payload if exists' do
      existing = create(:event_scope,
                        external_id: payload['id'],
                        kind: EventScope::TOURNAMENT,
                        name: 'Old name')
      service.call

      existing.reload
      expect(existing.name).to eq(payload['name'])
    end
  end

  describe 'season' do
    it 'creates new from payload' do
      service.call
      created = EventScope.find_by(external_id: payload['current_season']['id'])
      expect(created).not_to be_nil
    end

    it 'updates from payload if exists' do
      existing = create(:event_scope,
                        external_id: payload['current_season']['id'],
                        kind: EventScope::SEASON,
                        name: 'Old name')
      service.call

      existing.reload
      expect(existing.name).to eq(payload['current_season']['name'])
    end
  end

  describe '.call' do
    let(:title_external_id) { payload['sport']['id'] }
    let(:title_name) { payload['sport']['name'] }

    let(:tournament_external_id) { payload['id'] }
    let(:tournament_name) { payload['name'] }

    let(:country_external_id) { payload['category']['id'] }
    let(:country_name) { payload['category']['name'] }

    let(:season_external_id) { payload['current_season']['id'] }
    let(:season_name) { payload['current_season']['name'] }

    let(:title) { Title.find_by(external_id: title_external_id) }
    let(:country) { EventScope.find_by(external_id: country_external_id) }
    let(:tournament) { EventScope.find_by(external_id: tournament_external_id) }
    let(:season) { EventScope.find_by(external_id: season_external_id) }

    before do
      service.call
    end

    it('creates title as Title') { expect(title).is_a? Title }

    it 'fills title without kind' do
      expect(title)
        .to have_attributes(
          name: title_name,
          kind: 'sports'
        )
    end

    it('creates country as EventScope') { expect(country).is_a? EventScope }

    it 'fills country attributes' do
      expect(country)
        .to have_attributes(
          name: country_name,
          title: title,
          kind: 'country'
        )
    end

    it('creates tournament as EventScope') do
      expect(tournament).is_a? EventScope
    end

    it 'fills tournament attributes' do
      expect(tournament)
        .to have_attributes(
          name: tournament_name,
          title: title,
          event_scope: country,
          kind: EventScope::TOURNAMENT
        )
    end

    it('creates season as EventScope') { expect(season).is_a? EventScope }

    it 'fills season attributes' do
      expect(season)
        .to have_attributes(
          name: season_name,
          title: title,
          event_scope: tournament,
          kind: EventScope::SEASON
        )
    end
  end
end
