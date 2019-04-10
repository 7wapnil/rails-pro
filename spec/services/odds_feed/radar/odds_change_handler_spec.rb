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
        expect{ subject.handle }
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

      it do
        expect{ subject.handle }
          .to raise_error(
                OddsFeed::InvalidMessageError,
                "Event type with external ID #{external_id} is not supported"
              )
      end
    end

    context 'outdated message' do
      before do
        event.update(remote_updated_at: Time.now.utc)
      end

      it do
        expect{ subject.handle }
          .to raise_error(
                OddsFeed::InvalidMessageError,
                /^Message came at/
              )
      end
    end

    context 'database not prepared' do
      it 'raises error if no producer found' do
        payload['odds_change']['product'] = '1000'
        expect{ subject.handle }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises error if no event found' do
        payload['odds_change']['event_id'] = '1000'
        expect{ subject.handle }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # Update event attributes in DB
  describe 'event update' do
    context 'attributes' do
      before do
        subject.handle
        event.reload
      end

      it 'updates payload status' do
        subject.handle
        event.reload
        expect(event.payload['state'].size).not_to be_zero
      end

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
