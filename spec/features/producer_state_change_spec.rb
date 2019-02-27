describe 'Producer state change feature. ' do
  let(:producer) { create(:producer) }
  let(:another_producer) { create(:producer) }
  let(:producers) { [producer, another_producer] }
  let(:time) { Time.zone.now }
  let(:time_milliseconds) { time.to_datetime.strftime('%Q').to_f }
  let(:metadata) do
    { 'scheduled_at' => time_milliseconds }
  end
  let(:client_double) { instance_double('OddsFeed::Radar::Client') }

  before do
    allow(OddsFeed::Radar::Client)
      .to receive(:new) { client_double }
    allow(client_double)
      .to receive(:product_recovery_initiate_request).and_return(
        'response' => {
          'response_code' => 'ACCEPTED'
        }
      )
  end

  include_context 'frozen_time'

  describe 'worker can set provider as unsubscribed actively' do
    before do
      producer.update(
        state: Radar::Producer::HEALTHY,
        last_successful_subscribed_at: time - 1.second
      )
      max_wait_time = Radar::Producer::HEARTBEAT_EXPIRATION_TIME_IN_SECONDS
      another_producer.update(
        state: Radar::Producer::HEALTHY,
        last_successful_subscribed_at: time - max_wait_time.seconds - 1.second
      )

      ::Radar::MissingHeartbeatWorker.new.perform(metadata)

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
    let(:message_generated_timestamp) do
      message_generated_at.to_datetime.strftime('%Q').to_i
    end
    let(:message_received_at_converted) do
      Time.zone.at(message_generated_timestamp / 1000)
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

    let(:snapshot_complete_payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      "<snapshot_complete request_id=\"#{producer.recovery_snapshot_id}\" "\
      " timestamp=\"1234578\" product=\"#{producer.id}\"/>"
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

    context 'with disconnected meaning, first' do
      Radar::Producer::STATES.values.each do |state, _expected_state|
        it "recovers #{state} producer" do
          previous_recover_long_time_ago = 1.year.ago
          producer.update(
            state: state,
            recover_requested_at: previous_recover_long_time_ago,
            last_successful_subscribed_at: before_message_received_at
          )
          OddsFeed::Radar::Alive::Handler.new(unsubscribed_payload).handle
          producer.reload

          expect(producer.state).to eq Radar::Producer::RECOVERING
        end
      end
    end

    context 'with disconnected meaning, after recovery' do
      Radar::Producer::STATES.values.each do |state|
        it "does not change #{state} producer state" do
          previous_recover_recently = Time.current
          producer.update(
            state: state,
            recover_requested_at: previous_recover_recently,
            last_successful_subscribed_at: before_message_received_at
          )
          OddsFeed::Radar::Alive::Handler.new(unsubscribed_payload).handle
          producer.reload

          expect(producer.state).to eq state
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
            .to eq Time.zone.strptime(message_generated_timestamp.to_s, '%Q')
        end
      end
    end

    context 'with connected meaning for unsubscribed producer' do
      let(:node_id) { Faker::Number.number(2).to_s }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RADAR_MQ_NODE_ID').and_return(node_id)

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

    shared_examples 'snapshot_completed spec' do
      before do
        producer.update(
          recover_requested_at: time - 1.hour,
          recovery_snapshot_id: Faker::Number.number(2),
          recovery_node_id: Faker::Number.number(2),
          last_disconnection_at: initial_last_disconnection_at,
          state: initial_state
        )
        OddsFeed::Radar::SnapshotCompleteHandler
          .new(snapshot_complete_payload).handle
        producer.reload
      end

      it 'sets psets recovering producer roducer in correct state' do
        expect(producer.state).to eq expected_outcome
      end

      it 'controls recovery timestamp' do
        expect(producer.last_disconnection_at)
          .to eq expected_last_disconnection_at
      end
    end

    context 'with snapshot_completed, sets recovering producer as healthy' do
      it_behaves_like 'snapshot_completed spec' do
        let(:initial_last_disconnection_at) { 1.second.ago }
        let(:initial_state) { Radar::Producer::RECOVERING }
        let(:expected_outcome) { Radar::Producer::HEALTHY }
        let(:expected_last_disconnection_at) { nil }
      end
    end

    context 'with snapshot_completed, ignored for unsubscribed producer' do
      it_behaves_like 'snapshot_completed spec' do
        let(:initial_last_disconnection_at) { 1.second.ago }
        let(:initial_state) { Radar::Producer::UNSUBSCRIBED }
        let(:expected_outcome) { Radar::Producer::UNSUBSCRIBED }
        let(:expected_last_disconnection_at) { initial_last_disconnection_at }
      end
    end

    context 'with snapshot_completed, ignored for healthy producer' do
      it_behaves_like 'snapshot_completed spec' do
        let(:initial_last_disconnection_at) { 1.second.ago }
        let(:initial_state) { Radar::Producer::HEALTHY }
        let(:expected_outcome) { Radar::Producer::HEALTHY }
        let(:expected_last_disconnection_at) { initial_last_disconnection_at }
      end
    end
  end
end
