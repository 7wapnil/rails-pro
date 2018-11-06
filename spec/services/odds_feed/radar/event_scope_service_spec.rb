describe OddsFeed::Radar::EventScopeService do
  let(:payload) do
    XmlParser.parse(
      file_fixture('tournaments_response.xml').read
    )['tournaments']['tournament']
  end

  subject { OddsFeed::Radar::EventScopeService.new(payload) }

  describe '#find_or_create_title!' do
    context 'record created simultaneously' do
      let(:title_payload) do
        {
          name: payload['sport']['name'],
          external_id: payload['sport']['id']
        }
      end

      let!(:existing_title) { create(:title, title_payload) }
      let(:initialized_title) { build(:title, title_payload) }

      before do
        allow(Title)
          .to receive(:find_or_initialize_by)
          .and_return(initialized_title)
      end

      it 'fails to save the initialized title' do
        expect(initialized_title)
          .to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid)

        subject.send(:find_or_create_title!, payload['sport'])
      end

      it 'returns existing title' do
        expect(Title)
          .to receive(:find_by!)
          .with(external_id: title_payload[:external_id])
          .and_return(existing_title)

        subject.send(:find_or_create_title!, payload['sport'])
      end
    end
  end

  describe '#find_or_create_country!' do
    let(:country_payload) do
      {
        kind: :country,
        name: payload['category']['name'],
        external_id: payload['category']['id']
      }
    end

    let!(:existing_country) { create(:event_scope, country_payload) }
    let(:initialized_country) { build(:event_scope, country_payload) }

    before do
      allow(EventScope)
        .to receive(:find_or_initialize_by)
        .with(hash_including(kind: :country))
        .and_return(initialized_country)
    end

    context 'record created simultaneously' do
      it 'fails to save the initialized country' do
        expect(initialized_country)
          .to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid)

        subject.send(:find_or_create_country!, payload['category'])
      end

      it 'returns existing country' do
        expect(EventScope)
          .to receive(:find_by!)
          .with(kind: :country, external_id: country_payload[:external_id])
          .and_return(existing_country)

        subject.send(:find_or_create_country!, payload['category'])
      end
    end
  end

  context '.call' do
    let(:title_external_id) { payload['sport']['id'] }
    let(:title_name) { payload['sport']['name'] }

    let(:tournament_external_id) { payload['id'] }
    let(:tournament_name) { payload['name'] }

    let(:country_external_id) { payload['category']['id'] }
    let(:country_name) { payload['category']['name'] }

    let(:season_external_id) { payload['current_season']['id'] }
    let(:season_name) { payload['current_season']['name'] }

    before do
      subject.call
    end

    it 'creates title without kind' do
      title = Title.find_by(external_id: title_external_id)
      expect(title).is_a? Title
      expect(title.name).to eq(title_name)
      expect(title.kind).to eq('sports')
    end

    it 'creates country' do
      title = Title.find_by(external_id: title_external_id)
      country = EventScope.find_by(
        external_id: country_external_id
      )
      expect(country).is_a? EventScope
      expect(country.name).to eq(country_name)
      expect(country.title).to eq(title)
      expect(country.kind).to eq('country')
    end

    it 'creates tournament' do
      title = Title.find_by(external_id: title_external_id)
      country = EventScope.find_by(
        external_id: country_external_id
      )
      tournament = EventScope.find_by(
        external_id: tournament_external_id
      )
      expect(tournament).is_a? EventScope
      expect(tournament.name).to eq(tournament_name)
      expect(tournament.title).to eq(title)
      expect(tournament.event_scope).to eq(country)
      expect(tournament.kind).to eq('tournament')
    end

    it 'creates season' do
      title = Title.find_by(external_id: title_external_id)
      tournament = EventScope.find_by(
        external_id: tournament_external_id
      )
      season = EventScope.find_by(
        external_id: season_external_id
      )
      expect(season).is_a? EventScope
      expect(season.name).to eq(season_name)
      expect(season.title).to eq(title)
      expect(season.event_scope).to eq(tournament)
      expect(season.kind).to eq('season')
    end
  end
end
