# frozen_string_literal: true

describe ::Radar::AliveWorker do
  subject { described_class.new.perform(payload) }

  let(:node_id) { Faker::Number.number(4).to_i }
  let(:requested_at) { Time.zone.now.change(usec: 0) }
  let(:request_id) { requested_at.to_i }
  let(:timestamp) { "#{request_id}000" }
  let(:producer) { create(:producer, :healthy) }
  let(:payload_subscribed) { ::OddsFeed::Radar::AliveHandler::SUBSCRIBED_STATE }

  let(:heartbeat_limits) do
    OddsFeed::Radar::Producers::Heartbeatable::HEARTBEAT_INTERVAL_LIMITS
  end
  let(:heartbeat_limit) { heartbeat_limits[producer.code] }

  let(:payload) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
     "<alive product=\"#{producer.id}\" "\
     "timestamp=\"#{timestamp}\" subscribed=\"#{payload_subscribed}\"/>"
  end

  let(:recovery_code) do
    ::OddsFeed::Radar::Producers::RequestRecovery::ACCEPTED
  end

  let(:recovery_payload) do
    { 'response' => { 'response_code' => recovery_code } }
  end

  include_context 'frozen_time'

  before do
    producer

    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with('RADAR_MQ_NODE_ID').and_return(node_id)

    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)

    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:product_recovery_initiate_request)
      .and_return(recovery_payload)

    allow_any_instance_of(described_class)
      .to receive(:job_id)
      .and_return(123)
  end

  it 'logs extra data when job is done' do
    expect(Rails.logger)
      .to receive(:info)
      .with(
        hash_including(
          producer_subscription_state: producer.subscribed?,
          message_subscription_state: true,
          message_timestamp: timestamp.to_s,
          message_producer_id: producer.id.to_s
        )
      )
    subject
  end

  context 'when connection is stable' do
    it 'keeps subscription' do
      subject
      expect(producer.reload).to have_attributes(
        state: ::Radar::Producer::HEALTHY,
        last_subscribed_at: requested_at,
        last_disconnected_at: nil,
        recovery_snapshot_id: nil,
        recovery_node_id: nil,
        recovery_requested_at: nil
      )
    end

    context 'when currently recovering' do
      let(:producer) { create(:producer, :recovering) }

      it 'keeps subscription and does not change status' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::RECOVERING,
          last_subscribed_at: requested_at
        )
      end

      it 'does not request recovery' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .not_to receive(:product_recovery_initiate_request)
        subject
      end
    end

    context 'when messages stuck in queue and lose their order' do
      let(:timestamp) { producer.last_subscribed_at - 1.second }

      it 'update nothing' do
        expect { subject }.not_to change { producer.reload.last_subscribed_at }
      end
    end

    context 'when messages stucked in queue and lost their order' do
      let(:timestamp) { producer.last_subscribed_at - 1.second }

      it 'updates nothing' do
        expect { subject }.not_to change { producer.reload.last_subscribed_at }
      end
    end
  end

  context 'when registers disconnection and re-connects' do
    let(:last_subscribed_at) do
      heartbeat_limits[::Radar::Producer::LIVE_PROVIDER_CODE].ago - 1.second
    end

    let(:producer) do
      create(:liveodds_producer, :unsubscribed,
             last_subscribed_at: last_subscribed_at)
    end

    it 'requests recovery' do
      expect_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .with(
          product_code: producer.code,
          after: producer.last_disconnected_at,
          node_id: node_id,
          request_id: request_id
        )
        .and_return(recovery_payload)
      subject
    end

    it 'registers recovery' do
      subject
      expect(producer.reload).to have_attributes(
        state: ::Radar::Producer::RECOVERING,
        last_subscribed_at: requested_at,
        recovery_requested_at: requested_at,
        recovery_snapshot_id: request_id,
        recovery_node_id: node_id
      )
    end

    context 'on development environment' do
      before { allow(Rails.env).to receive(:development?).and_return(true) }

      it 'does not request recovery' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .not_to receive(:product_recovery_initiate_request)
          .and_return(recovery_payload)
        subject
      end

      it 'instantly recovers the producer' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::HEALTHY,
          last_subscribed_at: requested_at,
          last_disconnected_at: nil,
          recovery_requested_at: nil,
          recovery_snapshot_id: nil,
          recovery_node_id: nil
        )
      end
    end
  end

  context 'when does not register disconnection and re-connects' do
    let(:last_subscribed_at) do
      heartbeat_limits[::Radar::Producer::LIVE_PROVIDER_CODE].ago - 1.second
    end

    let(:producer) do
      create(:liveodds_producer, :healthy,
             last_subscribed_at: last_subscribed_at)
    end

    it 'requests recovery' do
      expect_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .with(
          product_code: producer.code,
          after: producer.last_subscribed_at,
          node_id: node_id,
          request_id: request_id
        )
        .and_return(recovery_payload)
      subject
    end

    it 'registers recovery' do
      subject
      expect(producer.reload).to have_attributes(
        state: ::Radar::Producer::RECOVERING,
        last_subscribed_at: requested_at,
        recovery_requested_at: requested_at,
        recovery_snapshot_id: request_id,
        recovery_node_id: node_id
      )
    end

    context 'on development environment' do
      before { allow(Rails.env).to receive(:development?).and_return(true) }

      it 'does not request recovery' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .not_to receive(:product_recovery_initiate_request)
          .and_return(recovery_payload)
        subject
      end

      it 'just refreshes the subscription' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::HEALTHY,
          last_subscribed_at: requested_at,
          recovery_requested_at: nil,
          recovery_snapshot_id: nil,
          recovery_node_id: nil
        )
      end
    end
  end

  context 'when have just established connection' do
    let(:payload_subscribed) { '0' }

    context 'and there is registered disconnection' do
      let(:producer) { create(:producer, :unsubscribed) }

      it 'requests recovery' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:product_recovery_initiate_request)
          .with(
            product_code: producer.code,
            after: producer.last_disconnected_at,
            node_id: node_id,
            request_id: request_id
          )
          .and_return(recovery_payload)
        subject
      end

      it 'registers recovery and refreshes subscription time' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::RECOVERING,
          last_subscribed_at: requested_at,
          recovery_requested_at: requested_at,
          recovery_snapshot_id: request_id,
          recovery_node_id: node_id
        )
      end

      context 'on development environment' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        it 'does not request recovery' do
          expect_any_instance_of(::OddsFeed::Radar::Client)
            .not_to receive(:product_recovery_initiate_request)
            .and_return(recovery_payload)
          subject
        end

        it 'instantly recovers the producer' do
          subject
          expect(producer.reload).to have_attributes(
            state: ::Radar::Producer::HEALTHY,
            last_subscribed_at: requested_at,
            last_disconnected_at: nil,
            recovery_requested_at: nil,
            recovery_snapshot_id: nil,
            recovery_node_id: nil
          )
        end
      end
    end

    context 'and there is no registered disconnection' do
      let(:producer) { create(:producer, :healthy) }

      it 'requests recovery' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:product_recovery_initiate_request)
          .with(
            product_code: producer.code,
            after: producer.last_subscribed_at,
            node_id: node_id,
            request_id: request_id
          )
          .and_return(recovery_payload)
        subject
      end

      it 'registers recovery and refreshes subscription time' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::RECOVERING,
          last_subscribed_at: requested_at,
          recovery_requested_at: requested_at,
          recovery_snapshot_id: request_id,
          recovery_node_id: node_id
        )
      end

      context 'on development environment' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        it 'does not request recovery' do
          expect_any_instance_of(::OddsFeed::Radar::Client)
            .not_to receive(:product_recovery_initiate_request)
            .and_return(recovery_payload)
          subject
        end

        it 'just refreshes subscription time' do
          subject
          expect(producer.reload).to have_attributes(
            state: ::Radar::Producer::HEALTHY,
            last_subscribed_at: requested_at,
            recovery_requested_at: nil,
            recovery_snapshot_id: nil,
            recovery_node_id: nil
          )
        end
      end
    end

    context 'and there is already registered recovery' do
      let(:producer) { create(:producer, :recovering) }

      it 'requests new recovery starting from last recovery request' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:product_recovery_initiate_request)
          .with(
            product_code: producer.code,
            after: producer.recovery_requested_at,
            node_id: node_id,
            request_id: request_id
          )
          .and_return(recovery_payload)
        subject
      end

      it 'registers new recovery starting from last recovery request' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::RECOVERING,
          last_subscribed_at: requested_at,
          recovery_requested_at: requested_at,
          recovery_snapshot_id: request_id,
          recovery_node_id: node_id
        )
      end

      context 'on development environment' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        it 'does not request recovery' do
          expect_any_instance_of(::OddsFeed::Radar::Client)
            .not_to receive(:product_recovery_initiate_request)
            .and_return(recovery_payload)
          subject
        end

        it 'makes producer healthy' do
          subject
          expect(producer.reload).to have_attributes(
            state: ::Radar::Producer::HEALTHY,
            last_subscribed_at: requested_at,
            recovery_requested_at: nil,
            recovery_snapshot_id: nil,
            recovery_node_id: nil
          )
        end
      end
    end
  end
end
