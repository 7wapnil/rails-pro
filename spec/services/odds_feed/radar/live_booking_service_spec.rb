# frozen_string_literal: true

describe OddsFeed::Radar::LiveBookingService do
  subject { described_class.new(event.external_id) }

  let(:subject_api) { described_class.new(event.external_id) }

  let(:event) do
    create(:event,
           :bookable,
           external_id: 'sr:match:11868180',
           traded_live: false)
  end
  let(:api_client) { ::OddsFeed::Radar::Client.instance }

  before do
    allow(subject_api).to receive(:api_client).and_return(api_client)
  end

  it 'skips operation if event already live' do
    event.update_attributes!(traded_live: true)
    allow(subject_api).to receive(:update_event)

    subject_api.call

    expect(subject_api).not_to have_received(:update_event)
  end

  it 'skips operation if event liveodds is not bookable' do
    event.update_attributes!(liveodds: 'booked')

    subject.call

    expect(event.traded_live).to be_falsey
  end

  context 'without event' do
    let(:event) do
      instance_double(Event.name, external_id: Faker::Number.number)
    end

    it 'is not processed' do
      expect(api_client).not_to receive(:book_live_coverage)
    end
  end

  context 'replay server' do
    before do
      allow(subject_api).to receive(:replay?).and_return(true)
    end

    it 'updates event traded live flag' do
      expect(event.traded_live).to be_falsy

      subject_api.call
      event.reload

      expect(event.traded_live).to be_truthy
    end

    it 'does not make an API request' do
      allow(subject_api).to receive(:book_live_coverage)
      subject_api.call
      expect(subject_api).not_to have_received(:book_live_coverage)
    end
  end

  context 'production mode' do
    before do
      allow(subject_api).to receive(:replay?).and_return(false)
    end

    it 'books live through API' do
      response = { response: { response_code: 'OK' } }

      allow(api_client)
        .to receive(:book_live_coverage)
        .and_return(HashWithIndifferentAccess.new(response))

      subject_api.call
      event.reload

      expect(event.traded_live).to be_truthy
    end

    it 'raises error on bad response' do
      response = { response: { response_code: 'BAD_REQUEST',
                               message: 'Already booked' } }

      allow(api_client)
        .to receive(:book_live_coverage)
        .and_return(HashWithIndifferentAccess.new(response))

      expect { subject_api.call }
        .to raise_error(::OddsFeed::InvalidResponseError)
    end
  end
end
