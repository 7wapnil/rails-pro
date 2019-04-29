# frozen_string_literal: true

describe OddsFeed::Radar::FixtureChangeHandler do
  subject { described_class.new(payload) }

  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:external_event_id) { 'sr:match:1234' }
  let!(:event) { create(:event, external_id: external_event_id) }
  let(:producer_id) { prematch_producer.id.to_s }
  let(:change_type) { '4' }

  let(:payload) do
    {
      'fixture_change' => {
        'event_id' => external_event_id,
        'change_type' => change_type,
        'product' => producer_id
      }
    }
  end

  before do
    allow(EventsManager::EventLoader).to receive(:call).and_return(event)
  end

  describe 'validation' do
    context 'invalid event type' do
      let(:external_event_id) { 'sr:unknown:1234' }

      it 'rejects unknown event type handling' do
        subject.handle
        expect(EventsManager::EventLoader)
          .not_to have_received(:call)
      end
    end
  end

  describe 'update event data' do
    before { subject.handle }

    it 'updates event producer if changed' do
      expect(event.reload.producer_id).to eq(prematch_producer.id)
    end

    context 'cancelled message type' do
      let(:change_type) { '3' }

      it 'deactivates event' do
        expect(event.reload.active).to be_falsy
      end
    end
  end
end
