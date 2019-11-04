# frozen_string_literal: true

describe OddsFeed::Radar::AliveHandler do
  subject { described_class.new(payload).handle }

  let(:producer) { create(:producer, :healthy) }
  let(:requested_at) { Time.zone.now.change(usec: 0) }
  let(:timestamp) { "#{requested_at.to_i}000" }
  let(:payload_subscribed) { described_class::SUBSCRIBED_STATE }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
       "<alive product=\"#{producer.id}\" "\
       "timestamp=\"#{timestamp}\" subscribed=\"#{payload_subscribed}\"/>"
    )
  end

  before do
    allow(Thread.current).to receive(:[]=)
    allow(OddsFeed::Radar::Producers::KeepSubscription)
      .to receive(:call)
      .and_return(true)
    allow(OddsFeed::Radar::Producers::RequestRecovery)
      .to receive(:call)
      .and_return(true)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'writes useful information to logs' do
    expect(Thread.current).to receive(:[]=).with(:producer_id, producer.id)
    expect(Thread.current)
      .to receive(:[]=)
      .with(:producer_subscription_state, producer.subscribed?)
    expect(Thread.current)
      .to receive(:[]=)
      .with(:message_subscription_state, true)
    subject
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'keeps subscription' do
    expect(OddsFeed::Radar::Producers::KeepSubscription)
      .to receive(:call)
      .with(producer: producer, requested_at: requested_at)
    subject
  end

  it 'does not instantly request recovery' do
    expect(OddsFeed::Radar::Producers::RequestRecovery).not_to receive(:call)
    subject
  end

  context 'on out-dated message' do
    let(:timestamp) { 1.minute.ago.to_i * 1000 }
    let(:producer) do
      create(:producer, last_subscribed_at: Time.zone.now)
    end

    it 'ignores out-dated message' do
      expect(OddsFeed::Radar::Producers::KeepSubscription).not_to receive(:call)
      subject
    end
  end

  context 'when unsubscribed according to message' do
    let(:payload_subscribed) { '0' }

    it 'does not silently keep subscription' do
      expect(OddsFeed::Radar::Producers::KeepSubscription).not_to receive(:call)
      subject
    end

    it 'instantly requests recovery' do
      expect(OddsFeed::Radar::Producers::RequestRecovery)
        .to receive(:call)
        .with(producer: producer)
      subject
    end

    it 'updates subscription time' do
      subject
      expect(producer.reload).to have_attributes(
        last_subscribed_at: requested_at
      )
    end

    context 'on failed recovery' do
      before do
        allow(OddsFeed::Radar::Producers::RequestRecovery)
          .to receive(:call)
          .and_return(false)
      end

      it 'does not update subscription time' do
        expect { subject }.not_to change { producer.reload.last_subscribed_at }
      end
    end

    context 'when recovery is disabled' do
      let(:producer) { create(:producer, :unsubscribed) }

      before do
        allow(::Radar::Producer)
          .to receive(:recovery_disabled?)
          .and_return(true)
      end

      it 'skips recovery and recognizes producer as subscribed' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::HEALTHY,
          last_subscribed_at: requested_at
        )
      end
    end
  end
end
