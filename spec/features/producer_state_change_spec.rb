describe 'Producer state change feature. ' do
  let(:producer) { create(:producer) }
  let(:another_producer) { create(:producer) }
  let(:producers) { [producer, another_producer] }
  let(:time) { Time.zone.now }

  include_context 'frozen_time'

  describe 'worker can set provider as unsubscribed actively' do
    before do
      producer.update(
        state: Radar::Producer::HEALTHY,
        last_successful_subscribed_at: time - 1.second
      )
      another_producer.update(
        state: Radar::Producer::HEALTHY,
        last_successful_subscribed_at: time - 61.second
      )

      ::Radar::MissingHeartbeatWorker.new.perform

      producers.each(&:reload)
    end

    it 'unsubscribes expired producer' do
      expect(another_producer.state).to eq Radar::Producer::UNSUBSCRIBED
    end

    it 'does not expire active producer' do
      expect(producer.state).to eq Radar::Producer::HEALTHY
    end
  end

  describe 'when alive message received' do
    let(:message_generated_at) { time - 2.seconds }
    let(:message_generated_timestamp) { message_generated_at.to_i }
    let(:message_received_at_converted) do
      Time.zone.at(message_generated_timestamp)
    end
    let(:after_message_received_at) do
      message_received_at_converted + 1.second
    end
    let(:before_message_received_at) do
      message_received_at_converted - 1.second
    end
    let(:unsubscribed_payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
       "<alive product=\"#{producer.id}\" "\
       "timestamp=\"#{message_generated_timestamp}\" subscribed=\"0\"/>"
      )
    end
    let(:subscribed_payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
       "<alive product=\"#{producer.id}\" "\
       "timestamp=\"#{message_generated_timestamp}\" subscribed=\"1\"/>"
      )
    end

    context 'with expired timestamp' do
      Radar::Producer::STATES.values.each do |state|
        it "does not influence on #{state} producer status" do
          producer.update(
            state: state,
            last_successful_subscribed_at: after_message_received_at
          )
          OddsFeed::Radar::Alive::Handler.new(unsubscribed_payload).handle
          producer.reload

          expect(producer.state).to eq state
        end
      end
    end

    context 'with disconnected meaning' do
      Radar::Producer::STATES.values.each do |state|
        it "unsubscribes #{state} producer" do
          producer.update(
            state: state,
            last_successful_subscribed_at: before_message_received_at
          )
          OddsFeed::Radar::Alive::Handler.new(unsubscribed_payload).handle
          producer.reload

          expect(producer.state).to eq Radar::Producer::UNSUBSCRIBED
        end
      end
    end

    Radar::Producer::SUBSCRIBED_STATES.values.each do |state|
      context "with connected meaning for subscribed and #{state} producer" do
        before do
          producer.update(
            state: state,
            last_successful_subscribed_at: message_generated_at - 1.second
          )
          OddsFeed::Radar::Alive::Handler.new(subscribed_payload).handle
          producer.reload
        end

        it "does not change state of #{state} producer" do
          expect(producer.state).to eq state
        end

        it "stores last_successful_subscribed_at for #{state} producer" do
          expect(producer.last_successful_subscribed_at)
            .to eq Time.zone.at(message_generated_timestamp)
        end
      end
    end

    context 'with connected meaning for unsubscribed producer' do
      let(:node_id) { Faker::Number.number(2).to_s }
      let(:client_double) { instance_double('OddsFeed::Radar::Client') }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RADAR_MQ_NODE_ID').and_return(node_id)

        allow(OddsFeed::Radar::Client)
          .to receive(:new) { client_double }
        allow(client_double)
          .to receive(:product_recovery_initiate_request).and_return(
            'response' => {
              'response_code' => 'ACCEPTED'
            }
          )

        producer.update(
          recover_requested_at: nil,
          recovery_snapshot_id: nil,
          recovery_node_id: nil,
          state: Radar::Producer::UNSUBSCRIBED,
          last_successful_subscribed_at: message_generated_at - 1.second
        )
        OddsFeed::Radar::Alive::Handler.new(subscribed_payload).handle
        producer.reload
      end

      it 'recovers unsubscribed producer' do
        expect(producer.state).to eq Radar::Producer::RECOVERING
      end

      it 'stores recovery attributes' do
        expect(producer)
          .to have_attributes(
            recover_requested_at: Time.zone.now,
            recovery_snapshot_id: Time.zone.now.to_i,
            recovery_node_id: node_id.to_i
          )
      end
    end

    describe 'snapshot_completed message processing' do
      let(:payload) do
        XmlParser.parse(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      "<snapshot_complete request_id=\"#{producer.recovery_snapshot_id}\" "\
      " timestamp=\"1234578\" product=\"#{producer.id}\"/>"
        )
      end

      it 'sets recovering producer as healthy' do
        producer.update(
          recover_requested_at: time - 1.hour,
          recovery_snapshot_id: Faker::Number.number(2),
          recovery_node_id: Faker::Number.number(2),
          state: Radar::Producer::RECOVERING
        )
        OddsFeed::Radar::SnapshotCompleteHandler.new(payload).handle
        producer.reload

        expect(producer.state).to eq Radar::Producer::HEALTHY
      end

      it 'ignores snapshot for unsubscribed producer' do
        producer.update(
          recover_requested_at: time - 1.hour,
          recovery_snapshot_id: Faker::Number.number(2),
          recovery_node_id: Faker::Number.number(2),
          state: Radar::Producer::UNSUBSCRIBED
        )
        OddsFeed::Radar::SnapshotCompleteHandler.new(payload).handle
        producer.reload

        expect(producer.state).to eq Radar::Producer::UNSUBSCRIBED
      end

      it 'ignores snapshot for healthy producer' do
        producer.update(
          recover_requested_at: time - 1.hour,
          recovery_snapshot_id: Faker::Number.number(2),
          recovery_node_id: Faker::Number.number(2),
          state: Radar::Producer::HEALTHY
        )
        OddsFeed::Radar::SnapshotCompleteHandler.new(payload).handle
        producer.reload

        expect(producer.state).to eq Radar::Producer::HEALTHY
      end
    end
  end
end
