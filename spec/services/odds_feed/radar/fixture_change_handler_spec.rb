# frozen_string_literal: true

describe OddsFeed::Radar::FixtureChangeHandler do
  subject { described_class.new(payload) }

  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:external_event_id) { 'sr:match:1234' }
  let(:persisted_event_id) { external_event_id }
  let!(:event) { create(:event, external_id: persisted_event_id) }
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
    allow(::Radar::ScheduledEvents::EventLoadingWorker)
      .to receive(:perform_async)
    allow(EventsManager::EventLoader).to receive(:call).and_return(event)
  end

  include_context 'asynchronous to synchronous'

  describe 'validation' do
    context 'invalid event type' do
      let(:external_event_id) { 'sr:unknown:1234' }
      let(:persisted_event_id) { 'sr:match:1234' }

      it 'rejects unknown event type handling' do
        subject.handle
        expect(EventsManager::EventLoader).not_to have_received(:call)
      end
    end

    context 'with live producer and event that does not exist' do
      let(:persisted_event_id) { 'sr:match:322' }
      let(:producer_id) { liveodds_producer.id.to_s }

      it 'does not proceed event updating' do
        subject.handle
        expect(EventsManager::EventLoader).not_to have_received(:call)
      end
    end

    context 'with live producer and event that exist' do
      let(:producer_id) { liveodds_producer.id.to_s }

      it 'proceeds event updating' do
        subject.handle
        expect(EventsManager::EventLoader).to have_received(:call)
      end
    end

    context 'with event that does not exist' do
      let(:persisted_event_id) { 'sr:match:322' }
      let(:subject_stub) { described_class.new(payload) }

      let(:new_event_xml_payload) do
        XmlParser.parse(file_fixture('radar_event_fixture.xml').read)
      end
      let(:external_event_id) do
        new_event_xml_payload.dig('fixtures_fixture', 'fixture', 'id')
      end
      let(:competitor_payload) do
        XmlParser.parse(file_fixture('radar_competitor_profile.xml').read)
      end

      let(:found_event) { Event.find_by(external_id: external_event_id) }

      before do
        allow(EventsManager::EventLoader).to receive(:call).and_call_original
        allow(::Radar::ScheduledEvents::EventLoadingWorker)
          .to receive(:perform_async)
          .and_call_original
        allow_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:event_raw)
          .with(external_event_id)
          .and_return(new_event_xml_payload)
        allow_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:competitor_profile)
          .and_return(competitor_payload)

        allow(subject_stub)
          .to receive(:raise)
          .with(SilentRetryJobError, any_args)
      end

      it 'raises an error' do
        allow(subject_stub).to receive(:raise).and_call_original
        expect { subject.handle }.to raise_error(
          SilentRetryJobError,
          I18n.t('errors.messages.nonexistent_event', id: external_event_id)
        )
      end

      it 'asynchronously preloads it' do
        subject_stub.handle
        expect(found_event).not_to be_nil
      end

      it 'preloads event only once' do
        expect { subject_stub.handle }.to change(Event, :count).by(1)
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
