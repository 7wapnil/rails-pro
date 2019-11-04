# frozen_string_literal: true

describe ::Radar::MissingHeartbeatWorker do
  subject { described_class.new.perform }

  let(:heartbeat_limits) do
    OddsFeed::Radar::Producers::Heartbeatable::HEARTBEAT_INTERVAL_LIMITS
  end

  let(:live_heartbeat_limit) do
    heartbeat_limits[::Radar::Producer::LIVE_PROVIDER_CODE]
  end
  let(:live_producer) do
    create(:liveodds_producer, :healthy,
           last_subscribed_at: live_heartbeat_limit.ago - 1.second)
  end

  let(:prematch_heartbeat_limit) do
    heartbeat_limits[::Radar::Producer::PREMATCH_PROVIDER_CODE]
  end
  let(:prematch_producer) do
    create(
      :prematch_producer, :healthy,
      last_subscribed_at: prematch_heartbeat_limit.ago - 1.second
    )
  end

  include_context 'frozen_time'

  before do
    live_producer
    prematch_producer
  end

  context 'when only live producer is expired' do
    let(:prematch_producer) { create(:prematch_producer, :healthy) }

    it 'registers disconnection for live producer' do
      subject
      expect(live_producer.reload).to have_attributes(
        state: ::Radar::Producer::UNSUBSCRIBED,
        last_disconnected_at: live_producer.last_subscribed_at
      )
    end

    it 'does not register disconnection for prematch producer' do
      expect { subject }.not_to change { prematch_producer.reload.state }
    end
  end

  context 'when only prematch producer has disconnection_at, but is healthy' do
    let(:live_producer) { create(:liveodds_producer, :healthy) }
    let(:prematch_producer) do
      create(
        :prematch_producer, :healthy,
        last_disconnected_at: 3.days.ago,
        last_subscribed_at: prematch_heartbeat_limit.ago - 1.second
      )
    end

    it 're-registers disconnection for prematch producer' do
      subject
      expect(prematch_producer.reload).to have_attributes(
        state: ::Radar::Producer::UNSUBSCRIBED,
        last_disconnected_at: prematch_producer.last_subscribed_at
      )
    end

    it 'does not register disconnection for live producer' do
      expect { subject }.not_to(change { live_producer.reload.state })
    end
  end

  context 'when both producers have disconnection_at, but are not healthy' do
    let(:prematch_producer) do
      create(
        :prematch_producer, :unsubscribed,
        last_subscribed_at: prematch_heartbeat_limit.ago - 1.second
      )
    end
    let(:live_producer) do
      create(:liveodds_producer, :recovering,
             last_subscribed_at: live_heartbeat_limit.ago - 1.second)
    end

    it 'does not register disconnection for recovering live producer' do
      expect { subject }.not_to change { live_producer.reload.state }
    end

    it 'does not register disconnection for unsubscribed prematch producer' do
      expect { subject }.not_to change { prematch_producer.reload.state }
    end
  end
end
