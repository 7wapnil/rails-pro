# frozen_string_literal: true

describe OddsFeed::Radar::FixtureChangeHandler do
  subject { described_class.new(payload) }

  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:external_event_id) { 'sr:match:1234' }
  let!(:event) { create(:event, external_id: external_event_id) }
  let(:producer_id) { prematch_producer.id.to_s }
  let(:change_type) { '4' }
  let(:client_double) { double }
  let(:parsed_time) do
    DateTime.strptime(payload['fixture_change']['start_time'].first(10), '%s')
  end

  let(:payload) do
    {
      'fixture_change' => {
        'event_id' => external_event_id,
        'change_type' => change_type,
        'product' => producer_id,
        'start_time' => DateTime.now.strftime('%Q')
      }
    }
  end

  before do
    allow(EventsManager::EventLoader).to receive(:call).and_return(event)
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:event).and_return(client_double)
    allow(client_double)
      .to receive(:payload).and_return('start_time' => parsed_time)
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
    context 'does not update from prematch to liveodds' do
      let(:initial_producer_id) { event.producer_id }

      it 'updates event producer if changed' do
        subject.handle
        expect(event.reload.producer_id).to eq(initial_producer_id)
      end
    end

    context 'cancelled message type' do
      let(:change_type) { '3' }

      it 'deactivates event' do
        subject.handle
        expect(event.reload.active).to be_falsy
      end
    end
  end
end
