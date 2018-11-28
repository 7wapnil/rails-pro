describe OddsFeed::Radar::EventAdapter do
  let(:payload) do
    XmlParser.parse(
      file_fixture('radar_event_fixture.xml').read
    )['fixtures_fixture']['fixture']
  end
  let(:event_id) { 'sr:match:8696826' }
  let(:event_name) { 'IK Oddevold VS Tvaakers IF' }
  let(:tournament_attributes) do
    {
      name: 'Div 1 Sodra',
      external_id: 'sr:tournament:68',
      kind: 'tournament',
      title: title
    }
  end
  let(:season_attributes) do
    {
      name: 'Div 1, Sodra 2016',
      external_id: 'sr:season:12346',
      kind: 'season',
      title: title
    }
  end
  let(:country_attributes) do
    {
      name: 'Sweden',
      external_id: 'sr:category:9',
      kind: 'country',
      title: title
    }
  end
  let!(:title) { create(:title, external_id: 'sr:sport:1', name: 'Soccer') }

  describe '#result' do
    subject(:result) { described_class.new(payload).result }

    let(:tournament) { build(:event_scope, tournament_attributes) }
    let(:season) { build(:event_scope, season_attributes) }
    let(:country) { build(:event_scope, country_attributes) }

    context 'when database have all scopes' do
      before do
        tournament.save!
        season.save!
        country.save!
      end

      it 'loads existing tournament from db' do
        result_tournament = result.event_scopes.detect(&:tournament?)
        expect(result_tournament).to eq tournament
      end

      it 'loads existing season from db' do
        result_season = result.event_scopes.detect(&:season?)
        expect(result_season).to eq season
      end

      it 'loads existing country from db' do
        result_country = result.event_scopes.detect(&:country?)
        expect(result_country).to eq country
      end
    end

    context 'when database does not have scopes for give event' do
      it 'creates tournament scope from event payload' do
        result_tournament = result.event_scopes.detect(&:tournament?)
        expect(result_tournament).to have_attributes(tournament_attributes)
      end

      it 'creates season scope from event payload' do
        result_season = result.event_scopes.detect(&:season?)
        expect(result_season).to have_attributes(season_attributes)
      end

      it 'creates country scope from event payload' do
        result_country = result.event_scopes.detect(&:country?)
        expect(result_country).to have_attributes(country_attributes)
      end

      context 'creates title for event' do
        let(:result_title) { result.title }

        before { Title.destroy_all }

        it { expect { result.title }.to change(Title, :count).by(1) }

        it 'with copied attributes' do
          expect(result_title.name).to        eq(title.name)
          expect(result_title.external_id).to eq(title.external_id)
        end
      end
    end

    describe 'return value' do
      let(:expected_payload) do
        {
          'competitors': payload['competitors']
        }.stringify_keys
      end

      it('returns correct object') { expect(result).to be_a(Event) }
      it 'returns filled event' do
        expect(result).to have_attributes(
          external_id: event_id,
          payload: expected_payload,
          start_at: '2016-10-31T18:00:00+00:00'.to_time
        )
      end
    end

    describe 'archive_event_and_scopes!' do
      before do
        allow(EventArchive::Service).to receive(:call)
        result
      end

      it 'archives the event' do
        expect(EventArchive::Service).to have_received(:call).once
      end
    end

    # TODO: Refactor to EventArchive::Service spec
    context 'with real EventArchive::Service' do
      let(:archived_event) { ArchivedEvent.first }

      before { result }

      it 'creates one event_archive record at MongoDB' do
        expect(ArchivedEvent.count).to eq(1)
      end

      it 'arhives event with correct external id' do
        expect(archived_event.external_id).to eq(result.external_id)
      end

      it 'arhives event with correct scope size' do
        expect(archived_event.scopes.count).to eq(result.event_scopes.size)
      end
    end

    it 'returns generated event name' do
      expect(result.name).to eq(event_name)
    end

    it 'loads title from db' do
      expect(result.title).to eq title
    end

    context 'with invalid data' do
      it 'raises an error if competitors amount is wrong' do
        payload['competitors']['competitor']
          .push('Third competitor')
        expect { result }.to raise_error(NotImplementedError)
      end

      it 'raises error if tournament data is invalid' do
        payload['tournament'] = {}
        expect { result }.to raise_error(OddsFeed::InvalidMessageError)
      end
    end
  end
end
