describe Radar::AliveMessage do
  let(:cache) { Rails.cache }

  let(:valid_timestamp) { Time.now.utc.to_i }
  let(:valid_timestamp_datetime) { Time.at(valid_timestamp.to_i).to_datetime }

  describe '#from_hash' do
    subject { Radar::AliveMessage }
    context 'valid' do
      it 'returns message based on hash' do
        message = subject.from_hash(
          'product_id' => '1',
          'reported_at' => valid_timestamp.to_s,
          'subscribed' => '1'
        )
        expect(message.product_id).to eq 1
        expect(message.reported_at).to eq valid_timestamp_datetime
        expect(message.subscribed).to be true
      end
    end
  end

  describe '.save' do
    context 'valid alive call' do
      let(:key) { 'radar:last_successful_alive_message:1' }
      let(:message) do
        build(:alive_message, product_id: 1, reported_at: valid_timestamp)
      end

      before do
        cache.write(key, '0')
      end

      it 'saves last successful alive to cache' do
        message.save

        expect(cache.exist?(key)).to be(true)
        expect(cache.read(key)).to eq(valid_timestamp)
      end

      context 'expired timestamp' do
        let(:timestamp_in_future) { valid_timestamp + 1 }
        before do
          cache.write(key, timestamp_in_future)
        end

        it 'ignores timestamp update for expired case' do
          message.save

          expect(cache.exist?(key)).to be(true)
          expect(cache.read(key)).to eq(timestamp_in_future)
        end
      end
    end
    context 'subscribed is false' do
      let(:key) { 'radar:last_successful_alive_message:1' }
      let(:message) do
        build(:alive_message,
              product_id: 1,
              reported_at: valid_timestamp,
              subscribed: false)
      end
      let(:cache_value) { '0' }

      before do
        cache.write(key, cache_value)
      end

      it 'is not override cache value' do
        message.save

        expect(cache.read(key)).to eq(cache_value)
      end
    end
  end

  describe '.recover!' do
    let(:message) do
      build(
        :alive_message,
        product_id: 1,
        reported_at: valid_timestamp,
        subscribed: false
      )
    end

    before do
      allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
    end

    it 'calls SubscriptionRecovery for correct product and date' do
      time = Time.zone.now - 1.hour
      cache.write('radar:last_successful_alive_message:1', time.to_i)
      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: 1, start_at: time.to_i)
      message.recover!
    end

    it 'limits call SubscriptionRecovery to 72 hours' do
      Timecop.freeze(Time.zone.now)
      old_time = Time.zone.now - 1.week
      cache.write('radar:last_successful_alive_message:1', old_time.to_i)
      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: 1, start_at: nil)
      message.recover!
      Timecop.return
    end
  end
end
