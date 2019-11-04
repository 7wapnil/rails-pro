# frozen_string_literal: true

describe Radar::Producer do
  let(:snapshot_id) { Faker::Number.number(8).to_i }
  let(:node_id) { Faker::Number.number(4).to_i }
  let(:recovery_time) { Faker::Date.backward(14).to_datetime }
  let(:another_producer) do
    create(:producer,
           recovery_requested_at: producer.recovery_requested_at - 1.day)
  end
  let(:control_state) { described_class::HEALTHY }
  let(:producer) do
    create(:producer,
           recovery_requested_at: recovery_time,
           recovery_snapshot_id: snapshot_id,
           recovery_node_id: node_id,
           state: control_state)
  end
  let(:live_producer) { create(:liveodds_producer) }
  let(:prematch_producer) { create(:prematch_producer) }
  let(:real_producers_set) { [live_producer, prematch_producer] }

  it { is_expected.to have_many(:events) }

  describe 'callbacks' do
    let!(:producer) { create(:producer, state: control_state) }

    it 'emits websocket event on update' do
      expect(WebSocket::Client.instance)
        .to receive(:trigger_provider_update)
        .with(producer)
        .once

      producer.update(state: described_class::RECOVERING)
    end

    it 'emits websocket event on state update only' do
      expect(WebSocket::Client.instance)
        .not_to receive(:trigger_provider_update)
      producer.update(last_subscribed_at: Time.zone.now)
    end
  end

  describe '.live' do
    it 'returns live producer' do
      real_producers_set
      expect(described_class.live).to eq live_producer
    end
  end

  describe '.prematch' do
    it 'returns prematch producer' do
      real_producers_set
      expect(described_class.prematch).to eq prematch_producer
    end
  end

  describe '.recovery_disabled?' do
    context 'on development environment' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'is disabled' do
        expect(described_class.recovery_disabled?).to eq(true)
      end

      context 'on RADAR_RECOVERY_ENABLED is empty string' do
        before do
          allow(ENV)
            .to receive(:[])
            .with('RADAR_RECOVERY_ENABLED')
            .and_return('')
        end

        it 'is disabled' do
          expect(described_class.recovery_disabled?).to eq(true)
        end
      end

      context 'on RADAR_RECOVERY_ENABLED is false' do
        before do
          allow(ENV)
            .to receive(:[])
            .with('RADAR_RECOVERY_ENABLED')
            .and_return('false')
        end

        it 'is disabled' do
          expect(described_class.recovery_disabled?).to eq(true)
        end
      end

      context 'on RADAR_RECOVERY_ENABLED is true' do
        before do
          allow(ENV)
            .to receive(:[])
            .with('RADAR_RECOVERY_ENABLED')
            .and_return('true')
        end

        it 'is enabled' do
          expect(described_class.recovery_disabled?).to eq(false)
        end
      end
    end
  end

  describe '#live?' do
    it 'returns false for prematch code' do
      real_producers_set
      expect(prematch_producer).not_to be_live
    end

    it 'return true for live code' do
      real_producers_set
      expect(live_producer).to be_live
    end
  end

  describe '#prematch?' do
    it 'returns true for prematch code' do
      real_producers_set
      expect(prematch_producer).to be_prematch
    end

    it 'return false for live code' do
      real_producers_set
      expect(live_producer).not_to be_prematch
    end
  end

  describe '#subscribed?' do
    it 'returns false for non live code' do
      allow(producer).to receive(:state)
        .and_return(described_class::UNSUBSCRIBED)
      expect(producer).not_to be_live
    end

    described_class::SUBSCRIBED_STATES.values.each do |status|
      it "returns true for subscribed state #{status}" do
        allow(producer).to receive(:state) { status }
        expect(producer).to be_subscribed
      end
    end
  end

  describe 'aasm transitions' do
    describe '#register_disconnection!' do
      let(:last_subscribed_at) { rand(10..30).seconds.ago.change(usec: 0) }

      before do
        producer.register_disconnection!(last_subscribed_at: last_subscribed_at)
      end

      it 'works' do
        expect(producer.reload).to have_attributes(
          state: described_class::UNSUBSCRIBED,
          last_disconnected_at: last_subscribed_at
        )
      end
    end

    describe '#initiate_recovery!' do
      let(:new_requested_at) { rand(10..20).seconds.ago.change(usec: 0) }
      let(:new_snapshot_id) { Faker::Number.number(4).to_i }
      let(:new_node_id) { Faker::Number.number(4).to_i }

      before do
        producer.initiate_recovery!(
          requested_at: new_requested_at,
          snapshot_id: new_snapshot_id,
          node_id: new_node_id
        )
      end

      it 'works' do
        expect(producer.reload).to have_attributes(
          state: described_class::RECOVERING,
          recovery_requested_at: new_requested_at,
          recovery_snapshot_id: new_snapshot_id,
          recovery_node_id: new_node_id
        )
      end
    end

    describe '#complete_recovery!' do
      let(:control_state) { described_class::RECOVERING }

      before { producer.complete_recovery! }

      it 'works' do
        expect(producer.reload).to have_attributes(
          state: described_class::HEALTHY,
          recovery_requested_at: nil,
          recovery_snapshot_id: nil,
          recovery_node_id: nil,
          last_disconnected_at: nil
        )
      end
    end

    describe '#skip_recovery!' do
      let(:control_state) { described_class::UNSUBSCRIBED }
      let(:requested_at) { rand(10..20).seconds.ago.change(usec: 0) }

      before { producer.skip_recovery!(requested_at: requested_at) }

      it 'works' do
        expect(producer.reload).to have_attributes(
          state: described_class::HEALTHY,
          last_subscribed_at: requested_at,
          last_disconnected_at: nil
        )
      end
    end
  end
end
