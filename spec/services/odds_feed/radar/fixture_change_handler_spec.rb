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
    it 'updates event producer if changed' do
      subject.handle
      expect(event.reload.producer_id).to eq(prematch_producer.id)
    end

    context 'cancelled message type' do
      let(:change_type) { '3' }

      it 'deactivates event' do
        subject.handle
        expect(event.reload.active).to be_falsy
      end
    end

    context 'invalid producer' do
      let(:producer_id) { rand(10..100) }
      let(:message) do
        I18n.t('errors.messages.nonexistent_producer', id: producer_id)
      end

      it 'does not raise error' do
        expect { subject.handle }.not_to raise_error
      end

      it 'log message' do
        expect(Rails.logger).to receive(:warn).with(message)

        subject.handle
      end
    end
  end
end
