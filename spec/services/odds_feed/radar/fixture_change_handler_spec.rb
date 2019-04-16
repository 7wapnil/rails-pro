# frozen_string_literal: true

describe OddsFeed::Radar::FixtureChangeHandler do
  subject { described_class.new(payload) }

  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:external_event_id) { 'sr:match:1234' }
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
    allow(::Radar::ScheduledEvents::IdEventLoadingWorker)
      .to receive(:perform_async)
    allow_any_instance_of(EventsManager::EventLoader).to receive(:call)
  end

  describe 'validation' do
    let(:subject_stub) { described_class.new(payload) }

    before do
      allow(subject_stub).to receive(:update_event)
    end

    context 'invalid event type' do
      let(:external_event_id) { 'sr:unknown:1234' }

      it 'rejects unknown event type handling' do
        subject_stub.handle
        expect(subject_stub).not_to have_received(:update_event)
      end
    end

    context 'live producer for non-exists event' do
      let(:producer_id) { liveodds_producer.id.to_s }

      it 'rejects event update' do
        subject_stub.handle
        expect(subject_stub).not_to have_received(:update_event)
      end
    end
  end

  describe 'update event data' do
    before do
      event = create(:event,
                     external_id: external_event_id,
                     active: true,
                     producer: liveodds_producer)

      allow_any_instance_of(EventsManager::EventLoader)
        .to receive(:call)
        .and_return(event)
    end

    it 'updates event data via events manager' do
      subject.handle
      expect(Event.where(external_id: external_event_id)).to be_exists
    end

    it 'updates event producer if changed' do
      subject.handle
      event = Event.find_by!(external_id: external_event_id)
      expect(event.producer_id).to eq(prematch_producer.id)
    end

    context 'cancelled message type' do
      let(:change_type) { '3' }

      it 'deactivates event' do
        subject.handle
        event = Event.find_by!(external_id: external_event_id)
        expect(event.active).to be_falsy
      end
    end
  end
end
