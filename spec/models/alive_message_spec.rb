describe Radar::AliveMessage do
  let(:cache) { Rails.cache }

  let(:valid_timestamp) { Time.now.utc.to_i }
  let(:valid_timestamp_datetime) { Time.at(valid_timestamp.to_i).to_datetime }

  let(:valid_input_data) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="' + valid_timestamp.to_s +
        '" subscribed="1"/>'
    )['alive']
  end

  let(:product_id_key) { 'product' }
  let(:reported_at_key) { 'timestamp' }
  let(:subscribed_key) { 'subscribed' }

  describe '#from_hash' do
    subject { Radar::AliveMessage }

    context 'integration with OddsFeed::Radar::AliveHandler' do
      it 'based on correct input data' do
        expect(valid_input_data.keys).to include product_id_key
        expect(valid_input_data.keys).to include reported_at_key
        expect(valid_input_data.keys).to include subscribed_key
      end
    end

    context 'with valid input' do
      it 'converts timestamp to datetime' do
        message = subject.from_hash(valid_input_data)
        expect(message.product_id).to eq 1
        expect(message.reported_at).to eq valid_timestamp_datetime
        expect(message.subscribed).to be true
      end

      it 'normalizes product_id to Integer' do
        modified_data =
          valid_input_data.clone.tap { |data| data[product_id_key] = 1 }
        message = subject.from_hash(modified_data)

        expect(message.product_id).to eq 1
        expect(message.reported_at).to eq valid_timestamp_datetime
        expect(message.subscribed).to be true
      end
    end

    context 'input validation' do
      it 'raises when reported_at is not provided' do
        expect do
          invalid_data =
            valid_input_data.clone.tap { |data| data[reported_at_key] = nil }
          subject.from_hash(invalid_data)
        end.to raise_error(StandardError)
      end

      it 'raises when product_id is not provided' do
        expect do
          invalid_data =
            valid_input_data.clone.tap { |data| data[product_id_key] = nil }
          subject.from_hash(invalid_data)
        end.to raise_error(StandardError)
      end

      it 'raises when product_id is not an integer' do
        expect do
          invalid_data =
            valid_input_data.clone.tap { |data| data[product_id_key] = 'Foo' }
          subject.from_hash(invalid_data)
        end.to raise_error(StandardError)
      end

      it 'raises when subscribed is not zero or one' do
        expect do
          invalid_data =
            valid_input_data.clone.tap { |data| data[subscribed_key] = 'FOO' }
          subject.from_hash(invalid_data)
        end.to raise_error(StandardError)
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
