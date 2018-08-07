describe OddsFeed::Radar::SubscriptionRecovery do
  let(:cache) { Rails.cache }
  let(:cache_key) { 'radar:last_recovery_call' }

  describe '.call' do
    before do
      body =
        <<-END_XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <response response_code="ACCEPTED">
          <action>
            Request for PRE ALL messages from bookmaker 25238 received
          </action>
          </response>
        END_XML
      stub_request(:post, %r{/recovery/initiate_request})
        .to_return(status: 202, body: body, headers: {})
    end

    it 'calls recovery intiate request API endpoint' do
      cache.write(cache_key, Time.zone.now - 1.minute)
      expect(a_request(:post, %r{/recovery/initiate_request}))
      described_class.call(product_id: 1, start_at: Time.now.to_i)
    end

    it 'stores last recovery call time' do
      Timecop.freeze(Time.zone.now)
      time = Time.zone.now
      cache.write(cache_key, Time.now - 1.year)
      described_class.call(product_id: 1, start_at: time.to_i)
      expect(cache.read(cache_key).to_i).to eq time.to_i
      Timecop.return
    end
  end

  describe '.rates_available?' do
    let(:timestamp) { Time.now.to_i }
    let(:timestamp_date_time) { Time.at(timestamp).to_datetime }

    it 'returns true when cache is empty' do
      cache.delete(cache_key)
      service = described_class.new(product_id: 1, start_at: timestamp)
      expect(service.rates_available?).to be true
    end

    it 'returns true when cache is older than timeout' do
      cache.write(cache_key, (timestamp_date_time - 40.seconds).to_i)
      service = described_class.new(product_id: 1, start_at: timestamp)
      expect(service.rates_available?).to be true
    end

    it 'returns false when cache is equal to timeout' do
      Timecop.freeze(timestamp_date_time)
      cache.write(cache_key, (timestamp_date_time - 30.seconds).to_i)
      service = described_class.new(product_id: 1, start_at: timestamp)
      expect(service.rates_available?).to be false
      Timecop.return
    end

    it 'returns false when cache is less that timeout' do
      cache.write(cache_key, (timestamp_date_time - 1.seconds).to_i)
      service = described_class.new(product_id: 1, start_at: timestamp)
      expect(service.rates_available?).to be false
    end
  end
end
