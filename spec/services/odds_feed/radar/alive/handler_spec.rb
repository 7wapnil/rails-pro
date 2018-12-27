describe OddsFeed::Radar::Alive::Handler do
  subject { described_class.new(payload) }

  let(:payload) { {} }
  let(:cache_key) do
    OddsFeed::Radar::Alive::Handler::SUBSCRIPTION_REPORT_KEY_PREFIX
  end
  let(:message_timestamp) { 153_235_393_409_8 }

  before do
    allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
  end

  context 'subscribed' do
    let(:payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="1532353934098" subscribed="1"/>'
      )
    end

    it 'updates subscription report timestamp' do
      allow(Rails.cache).to receive(:write)

      subject.handle

      expect(Rails.cache)
        .to have_received(:write)
        .with(cache_key + '1', message_timestamp)
    end

    it 'skips timestamp update if message outdated' do
      allow(Rails.cache)
        .to receive(:read)
        .with(cache_key + '1')
        .and_return(message_timestamp + 100_00)
      allow(Rails.cache).to receive(:write)

      subject.handle

      expect(Rails.cache)
        .not_to have_received(:write)
        .with(cache_key + '1', message_timestamp)
    end

    it 'updates application state' do
      ApplicationState.instance.live_connected = false
      expect(ApplicationState.instance.live_connected).to be_falsy

      subject.handle

      expect(ApplicationState.instance.live_connected).to be_truthy
    end
  end

  context 'not subscribed' do
    let(:payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<alive product="1" timestamp="1532353934098" subscribed="0"/>'
      )
    end

    it 'updates application state' do
      ApplicationState.instance.live_connected = true
      expect(ApplicationState.instance.live_connected).to be_truthy

      subject.handle

      expect(ApplicationState.instance.live_connected).to be_falsy
    end

    it 'call subscription recovery service' do
      last_subscribed_timestamp = 71.hours.ago.to_i
      allow(Rails.cache)
        .to receive(:read)
        .with(cache_key + '1')
        .and_return(last_subscribed_timestamp)

      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: 1, start_at: last_subscribed_timestamp)

      subject.handle
    end

    it 'call subscription recovery service expired' do
      last_subscribed_timestamp = 73.hours.ago.to_i
      allow(Rails.cache)
        .to receive(:read)
        .with(cache_key + '1')
        .and_return(last_subscribed_timestamp)

      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: 1, start_at: nil)

      subject.handle
    end
  end
end
