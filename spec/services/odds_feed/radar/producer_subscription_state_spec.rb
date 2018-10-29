describe OddsFeed::Radar::ProducerSubscriptionState do
  let(:product_id) { 1 }
  subject { described_class.new(product_id) }

  describe '.subscribed!' do
    let(:reported_at) { Time.now }

    context 'subscription report expired' do
      before do
        timestamp_in_future = reported_at.to_i + 1
        allow(subject)
          .to receive(:last_subscribed_reported_timestamp)
          .and_return(timestamp_in_future)
      end

      it 'ignores request' do
        expect(subject).to_not receive(:store_last_subscribed_at_timestamp)
        subject.subscribed!(reported_at)
      end
    end

    context 'with valid subscription report timestamp' do
      before do
        timestamp_in_past = reported_at.to_i - 1
        allow(subject)
          .to receive(:last_subscribed_reported_timestamp)
          .and_return(timestamp_in_past)
      end

      it 'stores last report timestamp' do
        expect(subject).to receive(:store_last_subscribed_at_timestamp)
          .with(reported_at.to_i)
        subject.subscribed!(reported_at)
      end
    end
  end

  describe '.recover_subscription!' do
    before do
      allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
    end

    it 'calls SubscriptionRecovery for correct product and date' do
      time = Time.zone.now - 1.hour
      allow(subject)
        .to receive(:last_subscribed_reported_timestamp)
        .and_return(time.to_i)
      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: product_id, start_at: time.to_i)
      subject.recover_subscription!
    end

    it 'limits call SubscriptionRecovery to 72 hours' do
      Timecop.freeze(Time.zone.now)
      old_time = Time.zone.now - 1.week
      allow(subject)
        .to receive(:last_subscribed_reported_timestamp)
        .and_return(old_time.to_i)
      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: product_id, start_at: nil)
      subject.recover_subscription!
      Timecop.return
    end
  end

  describe '.subscription_report_expired?' do
    it 'returns true if last report older or eq to 1 minute ago' do
      time = Time.zone.now
      Timecop.freeze(time)
      allow(subject)
        .to receive(:last_subscribed_reported_timestamp)
        .and_return((time - 1.minute).to_i)
      expect(subject.subscription_report_expired?).to be_truthy
      Timecop.return
    end

    it 'returns false if report exists newer than 1 minute ago' do
      time = Time.zone.now
      Timecop.freeze(time)
      allow(subject)
        .to receive(:last_subscribed_reported_timestamp)
        .and_return((time - 59.seconds).to_i)
      expect(subject.subscription_report_expired?).to be_falsey
      Timecop.return
    end
  end
end
