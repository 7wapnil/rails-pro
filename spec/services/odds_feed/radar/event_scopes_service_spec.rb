describe OddsFeed::Radar::EventScopesService do
  subject(:service) { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(
      file_fixture('tournaments_response.xml').read
    )['tournaments']['tournament'][0]
  end

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

  describe 'category' do
    it 'creates new from payload' do
      service.call
      created = EventScope.find_by(external_id: payload['category']['id'])
      expect(created).not_to be_nil
    end

    it 'updates from payload if exists' do
      existing = create(:event_scope,
                        external_id: payload['category']['id'],
                        kind: EventScope::CATEGORY,
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

    let(:category_external_id) { payload['category']['id'] }
    let(:category_name) { payload['category']['name'] }

    let(:season_external_id) { payload['current_season']['id'] }
    let(:season_name) { payload['current_season']['name'] }

    let(:title) { Title.find_by(external_id: title_external_id) }
    let(:category) { EventScope.find_by(external_id: category_external_id) }
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
          kind: Title::SPORTS
        )
    end

    it('creates category as EventScope') do
      expect(category).to be_an EventScope
    end

    it 'fills category attributes' do
      expect(category)
        .to have_attributes(
          name: category_name,
          title: title,
          kind: EventScope::CATEGORY
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
          event_scope: category,
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
