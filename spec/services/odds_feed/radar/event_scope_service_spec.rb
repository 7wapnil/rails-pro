describe OddsFeed::Radar::EventScopeService do
  subject(:service) { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(
      file_fixture('tournaments_response.xml').read
    )['tournaments']['tournament']
  end

  describe '#find_or_create_title!' do
    context 'with simultaneously created records' do
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

        allow(initialized_title)
          .to receive(:save!)
          .and_call_original

        allow(Title)
          .to receive(:find_by!)
          .and_call_original

        service.send(:find_or_create_title!, payload['sport'])
      end

      it 'calls save on initialized title' do
        expect(initialized_title)
          .to have_received(:save!).once
      end

      it 'fails to save the initialized title' do
        expect { initialized_title.save! }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'queries for existing title' do
        expect(Title)
          .to have_received(:find_by!)
          .with(external_id: title_payload[:external_id]).once
      end

      it 'returns existing title' do
        expect(
          Title.find_by!(external_id: title_payload[:external_id])
        ).to eq(existing_title)
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

      allow(initialized_country)
        .to receive(:save!)
        .and_call_original

      allow(EventScope)
        .to receive(:find_by!)
        .and_call_original

      service.send(:find_or_create_country!, payload['category'])
    end

    context 'with simultaneously created records' do
      it 'receives save on initialized country' do
        expect(initialized_country)
          .to have_received(:save!).once
      end

      it 'fails to save the initialized country' do
        expect { initialized_country.save! }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'queries event scope for existing country' do
        expect(EventScope)
          .to have_received(:find_by!)
          .with(kind: :country, external_id: country_payload[:external_id])
          .once
      end

      it 'returns existing country' do
        expect(
          EventScope.find_by!(
            kind: :country, external_id: country_payload[:external_id]
          )
        ).to eq(existing_country)
      end
    end
  end

  describe '#find_or_create_tournament!' do
    let(:tournament_payload) do
      {
        kind: :tournament,
        name: payload['name'],
        external_id: payload['id']
      }
    end

    let!(:existing_tournament) { create(:event_scope, tournament_payload) }
    let(:initialized_tournament) { build(:event_scope, tournament_payload) }

    before do
      allow(EventScope)
        .to receive(:find_or_initialize_by)
        .with(hash_including(kind: :tournament))
        .and_return(initialized_tournament)

      allow(initialized_tournament)
        .to receive(:save!)
        .and_call_original

      allow(EventScope)
        .to receive(:find_by!)
        .and_call_original

      service.send(:find_or_create_tournament!, payload)
    end

    context 'with simultaneously created records' do
      it 'calls save on initialized tournament' do
        expect(initialized_tournament)
          .to have_received(:save!).once
      end

      it 'fails to save the initialized tournament' do
        expect { initialized_tournament.save! }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'queiries event scope for existing tournamnet' do
        expect(EventScope)
          .to have_received(:find_by!)
          .with(kind: :tournament,
                external_id: tournament_payload[:external_id]).once
      end

      it 'returns existing tournament' do
        expect(
          EventScope.find_by!(
            kind: :tournament, external_id: tournament_payload[:external_id]
          )
        ).to eq existing_tournament
      end
    end
  end

  describe '#find_or_create_season!' do
    let(:season_payload) do
      {
        kind: :season,
        name: payload['current_season']['name'],
        external_id: payload['current_season']['id']
      }
    end

    let!(:existing_season) { create(:event_scope, season_payload) }
    let(:initialized_season) { build(:event_scope, season_payload) }

    before do
      allow(EventScope)
        .to receive(:find_or_initialize_by)
        .with(hash_including(kind: :season))
        .and_return(initialized_season)

      allow(initialized_season)
        .to receive(:save!)
        .and_call_original

      allow(EventScope)
        .to receive(:find_by!)
        .and_call_original

      service.send(:find_or_create_season!, payload)
    end

    context 'with simultaneously created records' do
      it 'calls initialized season save!' do
        expect(initialized_season)
          .to have_received(:save!).once
      end

      it 'fails to save the initialized season' do
        expect { initialized_season.save! }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'queries event scope for existing season' do
        expect(EventScope)
          .to have_received(:find_by!)
          .with(kind: :season, external_id: season_payload[:external_id])
          .once
      end

      it 'returns existing season' do
        expect(
          EventScope.find_by!(
            kind: :season, external_id: season_payload[:external_id]
          )
        ).to eq existing_season
      end
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
          kind: 'tournament'
        )
    end

    it('creates season as EventScope') { expect(season).is_a? EventScope }

    it 'fills season attributes' do
      expect(season)
        .to have_attributes(
          name: season_name,
          title: title,
          event_scope: tournament,
          kind: 'season'
        )
    end
  end
end
