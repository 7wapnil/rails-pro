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
  let!(:title) do
    create(:title, external_id: 'sr:sport:1', external_name: 'Soccer')
  end

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
        expect(result_tournament.event_scope).to be_an EventScope
      end

      it 'creates season scope from event payload' do
        result_season = event_scopes.find(&:season?)
        expect(result_season).to have_attributes(season_attributes)
        expect(result_season.event_scope).to be_an EventScope
      end

      it 'creates category scope from event payload' do
        result_category = event_scopes.find(&:category?)
        expect(result_category).to have_attributes(category_attributes)
        expect(result_category.event_scope).to be_nil
      end

      context 'creates title for event' do
        let(:result_title) { result.title }

        before { Title.destroy_all }

        it { expect { result.title }.to change(Title, :count).by(1) }

        it 'with copied attributes' do
          expect(result_title.external_name).to eq(title.external_name)
          expect(result_title.external_id).to eq(title.external_id)
        end
      end
    end

    describe 'return value' do
      let(:expected_liveodds) { payload['liveodds'] }

      it('returns correct object') { expect(result).to be_a(Event) }

      it 'returns filled event' do
        expect(result).to have_attributes(
          external_id: event_id,
          name: 'IK Oddevold VS Tvaakers IF',
          meta_title: nil,
          meta_description: nil,
          traded_live: false,
          liveodds: expected_liveodds
        )
      end

      context 'when traded_live is marked in fixture change' do
        before do
          payload['liveodds'] =
            OddsFeed::Radar::EventFixtureBasedFactory::BOOKED_FIXTURE_STATUS
        end

        it 'returns filled traded_live event' do
          expect(result).to have_attributes(
            external_id: event_id,
            name: 'IK Oddevold VS Tvaakers IF',
            meta_title: nil,
            meta_description: nil,
            traded_live: true,
            liveodds: expected_liveodds
          )
        end
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
