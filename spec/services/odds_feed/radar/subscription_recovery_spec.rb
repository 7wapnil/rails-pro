describe OddsFeed::Radar::SubscriptionRecovery do
  describe '.call' do
    let(:node_id) { '88' }
    let(:client_double) { instance_double('OddsFeed::Radar::Client') }
    let(:product) { Radar::Producer.find(1) }
    let(:recovery_time_timestamp) { 1_546_588_682 }
    let(:recovery_time) { Time.zone.at(recovery_time_timestamp) }
    let(:after_recovery_time) { recovery_time + 1.hour }
    let(:oldest_recovery_since) { recovery_time - 72.hours }

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
      ::Radar::Producer.update_all('recover_requested_at = NULL')

      Timecop.freeze(recovery_time)
    end

    after do
      Timecop.return
    end

    context 'with last_successful_subscribed_at expired' do
      before do
        allow(product)
          .to receive(:last_successful_subscribed_at) {
            oldest_recovery_since - 1.minute
          }

        described_class.call(product: product)
        after_recovery_time = recovery_time + 1.hour
        Timecop.freeze(after_recovery_time)
      end

      it 'calls recovery initiate request from API client' do
        expect(
          client_double
        ).to have_received(:product_recovery_initiate_request)
          .with(
            product_code: 'liveodds',
            after: oldest_recovery_since,
            node_id: node_id,
            request_id: recovery_time_timestamp
          )
          .once
      end

      it 'modifies original product' do
        expect(product)
          .to have_attributes(
            recover_requested_at: recovery_time,
            recovery_snapshot_id: recovery_time_timestamp,
            recovery_node_id: node_id.to_i
          )
      end
    end

    context 'with last_successful_subscribed_at appliable' do
      let(:last_successful_subscribed_at) { oldest_recovery_since + 1.minute }

      before do
        allow(product)
          .to receive(:last_successful_subscribed_at) {
            last_successful_subscribed_at
          }

        described_class.call(product: product)
        Timecop.freeze(after_recovery_time)
      end

      it 'calls recovery initiate request from API client' do
        expect(
          client_double
        ).to have_received(:product_recovery_initiate_request)
          .with(
            product_code: product.code,
            after: last_successful_subscribed_at,
            node_id: node_id,
            request_id: recovery_time_timestamp
          )
          .once
      end

      it 'modifies original product' do
        expect(product)
          .to have_attributes(
            recover_requested_at: recovery_time,
            recovery_snapshot_id: recovery_time_timestamp,
            recovery_node_id: node_id.to_i
          )
      end
    end

    context 'with rates limit reached' do
      before do
        ::Radar::Producer.update_all(recover_requested_at: 1.second.ago)
      end

      it 'raises when rates reached' do
        expect { described_class.call(product: product) }
          .to raise_error('Recovery rates reached')
      end
    end

    context 'with client response failure' do
      before do
        allow(client_double)
          .to receive(:product_recovery_initiate_request)
          .and_return(
            'response' => {
              'response_code' => 'FAILURE'
            }
          )
      end

      it 'raises when client responds unexpected way' do
        expect { described_class.call(product: product) }
          .to raise_error('Unsuccessful recovery')
      end
    end
  end
end
