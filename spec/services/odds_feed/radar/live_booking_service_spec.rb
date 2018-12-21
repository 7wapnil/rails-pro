describe OddsFeed::Radar::LiveBookingService do
  let(:event) do
    create(:event, external_id: 'sr:match:11868180', traded_live: false)
  end
  let(:api_client) { OddsFeed::Radar::Client.new }

  subject { described_class.new(event.external_id) }

  before do
    allow(subject).to receive(:api_client).and_return(api_client)
  end

  it 'skips operation if event already live' do
    event.update_attributes!(traded_live: true)
    allow(subject).to receive(:update_event)

    subject.call

    expect(subject).not_to have_received(:update_event)
  end

  context 'replay server' do
    before do
      allow(subject).to receive(:replay?).and_return(true)
    end

    it 'updates event traded live flag' do
      expect(event.traded_live).to be_falsy

      subject.call
      event.reload

      expect(event.traded_live).to be_truthy
    end

    it 'does not make an API request' do
      allow(subject).to receive(:book_live_coverage)
      subject.call
      expect(subject).not_to have_received(:book_live_coverage)
    end
  end

  context 'production mode' do
    before do
      allow(subject).to receive(:replay?).and_return(false)
    end

    it 'books live through API' do
      response = { response: { response_code: 'OK' } }

      allow(api_client)
        .to receive(:book_live_coverage)
        .and_return(HashWithIndifferentAccess.new(response))

      subject.call
      event.reload

      expect(event.traded_live).to be_truthy
    end

    it 'raises error on bad response' do
      response = { response: { response_code: 'BAD_REQUEST',
                               message: 'Already booked' } }

      allow(api_client)
        .to receive(:book_live_coverage)
        .and_return(HashWithIndifferentAccess.new(response))

      expect { subject.call }
        .to raise_error(::OddsFeed::InvalidResponseError)
    end
  end
end
