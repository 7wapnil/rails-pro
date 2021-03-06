# frozen_string_literal: true

describe OddsFeed::Radar::OddsChangeHandler do
  subject { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:external_id) { 'sr:match:1234' }
  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:event) do
    create(:event,
           external_id: external_id,
           remote_updated_at: nil,
           producer: prematch_producer)
  end

  before do
    allow(::EventsManager::EventLoader).to receive(:call).and_return(event)
    allow(::OddsFeed::Radar::MarketGenerator::Service).to receive(:call)
    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
    allow(EventsManager::Entities::Event)
      .to receive(:type_match?)
      .and_return(true)
  end

  # Message validation and checks
  describe 'validation' do
    context 'malformed payload' do
      let(:payload) { {} }

      it do
        expect { subject.handle }
          .to raise_error(
            OddsFeed::InvalidMessageError,
            'Odds change payload is malformed: {}'
          )
      end
    end

    context 'unsupported event type' do
      before do
        allow(EventsManager::Entities::Event)
          .to receive(:type_match?)
          .and_return(false)
      end

      let(:message) do
        {
          event_id: external_id,
          message: I18n.t('internal.errors.messages.unsupported_event_type')
        }
      end

      it do
        expect(Rails.logger).to receive(:warn).with(message)

        subject.handle
      end
    end

    context 'event is not ready' do
      before do
        event.update(ready: false)
      end

      let(:message) do
        {
          event_id: external_id,
          message: 'Event is not yet ready to be processed'
        }
      end

      it do
        expect(Rails.logger).to receive(:info).with(message)

        subject.handle
      end
    end

    context 'invalid producer' do
      before do
        payload['odds_change']['product'] = prematch_producer.id.to_s
      end

      let!(:event) do
        create(:event,
               external_id: external_id,
               remote_updated_at: nil,
               producer: liveodds_producer)
      end

      it 'does not update to producer with lower priority' do
        expect(event.reload.producer_id).to eq(liveodds_producer.id)
      end
    end
  end

  # Update event attributes in DB
  describe 'event update' do
    context 'attributes' do
      it 'updates event producer' do
        subject.handle
        event.reload
        expect(event.producer_id).to eq(::Radar::Producer::LIVE_PROVIDER_ID)
      end

      it 'updates remote timestamp' do
        subject.handle
        event.reload
        expect(event.remote_updated_at).not_to be_nil
      end
    end

    context 'status' do
      {
        0 => Event::NOT_STARTED,
        1 => Event::STARTED,
        2 => Event::SUSPENDED,
        3 => Event::ENDED,
        4 => Event::CLOSED,
        5 => Event::CANCELLED,
        6 => Event::DELAYED,
        7 => Event::INTERRUPTED,
        8 => Event::POSTPONED,
        9 => Event::ABANDONED
      }.stringify_keys.each do |radar_status, internal_status|
        it "update events status to #{internal_status}" do
          payload['odds_change']['sport_event_status']['status'] = radar_status
          subject.handle
          event.reload
          expect(event.status).to eq(internal_status)
        end
      end
    end
  end

  # Import odds data
  describe 'data import' do
    it 'skips import on empty markets list' do
      payload['odds_change']['odds'] = nil
      subject.handle
      expect(::OddsFeed::Radar::MarketGenerator::Service)
        .not_to have_received(:call)
    end

    it 'calls import service for markets' do
      subject.handle
      expect(::OddsFeed::Radar::MarketGenerator::Service)
        .to have_received(:call)
    end
  end

  # Final works
  describe 'notification' do
    it 'sends websocket event after import' do
      subject.handle
      expect(WebSocket::Client.instance)
        .to have_received(:trigger_event_update)
        .with(event)
    end
  end
end
