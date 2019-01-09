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
  let(:category_attributes) do
    {
      name: 'Sweden',
      external_id: 'sr:category:9',
      kind: EventScope::CATEGORY,
      title: title
    }
  end
  let!(:title) { create(:title, external_id: 'sr:sport:1', name: 'Soccer') }

  describe '#result' do
    subject(:result) { described_class.new(payload).result }

    let(:tournament) { build(:event_scope, tournament_attributes) }
    let(:season) { build(:event_scope, season_attributes) }
    let(:category) { build(:event_scope, category_attributes) }

    let(:event_scopes) { result.scoped_events.map(&:event_scope) }

    context 'when database have all scopes' do
      before do
        tournament.save!
        season.save!
        category.save!
      end

      it 'loads existing tournament from db' do
        result_tournament = event_scopes.find(&:tournament?)
        expect(result_tournament).to eq tournament
      end

      it 'loads existing season from db' do
        result_season = event_scopes.find(&:season?)
        expect(result_season).to eq season
      end

      it 'loads existing category from db' do
        result_category = event_scopes.find(&:category?)
        expect(result_category).to eq category
      end
    end

    context 'when database does not have scopes for given event' do
      it 'creates tournament scope from event payload' do
        result_tournament = event_scopes.find(&:tournament?)
        expect(result_tournament).to have_attributes(tournament_attributes)
      end

      it 'creates season scope from event payload' do
        result_season = event_scopes.find(&:season?)
        expect(result_season).to have_attributes(season_attributes)
      end

      it 'creates category scope from event payload' do
        result_category = event_scopes.find(&:category?)
        expect(result_category).to have_attributes(category_attributes)
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
          'competitors': payload['competitors'],
          'liveodds':    payload['liveodds']
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

      context 'on empty payload' do
        let(:payload) {}

        it 'return empty event' do
          expect(result).to      be_an Event
          expect(result.name).to be_nil
        end
      end
    end
  end
end
