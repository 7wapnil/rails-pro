describe OddsFeed::Radar::EventFixtureBasedFactory do
  let(:payload) do
    XmlParser.parse(
      file_fixture('radar_event_fixture.xml').read
    )['fixtures_fixture']['fixture']
  end
  let(:event_id) { 'sr:match:8696826' }
  let(:event_name) { 'IK Oddevold VS Tvaakers IF' }
  let(:event_description) { event_name }
  let(:start_at) { '2016-10-31T18:00:00+00:00'.to_time }
  let(:expected_liveodds) { payload['liveodds'] }

  describe '#event' do
    subject(:result) { described_class.new(fixture: payload).event }

    it('returns correct object') { expect(result).to be_a(Event) }

    it 'returns filled event' do
      expect(result).to have_attributes(
        external_id: event_id,
        name: event_name,
        description: event_description,
        traded_live: false,
        liveodds: expected_liveodds
      )
    end

    context 'when traded_live is marked in fixture change' do
      before do
        payload['liveodds'] =
          described_class::BOOKED_FIXTURE_STATUS
      end

      it 'returns filled traded_live event' do
        expect(result).to have_attributes(
          external_id: event_id,
          name: event_name,
          description: event_description,
          traded_live: true,
          liveodds: expected_liveodds
        )
      end
    end
  end
end
