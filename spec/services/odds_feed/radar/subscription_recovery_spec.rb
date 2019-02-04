describe OddsFeed::Radar::SubscriptionRecovery do
  describe '.call' do
    let(:node_id) { Faker::Number.number(4).to_s }
    let(:client_double) { instance_double(OddsFeed::Radar::Client.name) }
    let(:product) { create(:producer) }
    let(:another_product) { create(:producer) }
    let(:recovery_time_timestamp) { Faker::Time.backward(100).to_i }
    let(:recovery_time) { Time.zone.at(recovery_time_timestamp) }
    let(:after_recovery_time) { recovery_time + 1.hour }
    let(:oldest_recovery_since) do
      recovery_time -
        described_class::OLDEST_RECOVERY_AVAILABLE_IN_HOURS.hours
    end

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
            product_code: product.code,
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
      let(:original_state) { Radar::Producer::UNSUBSCRIBED }

      before do
        product.update(state: original_state)
        another_product.update(recover_requested_at: 1.second.ago)

        allow(Rails.logger).to receive(:error)

        described_class.call(product: product)
      end

      it 'writes rate error to logs' do
        expect(Rails.logger)
          .to have_received(:error)
          .with(described_class::RECOVERY_RATES_REACHED_MESSAGE)
          .once
      end

      it 'returns original producer' do
        expect(described_class.call(product: product))
          .to have_attributes(
            state: original_state
          )
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
          .to raise_error(described_class::UNSUCCESSFUL_RECOVERY_MESSAGE)
      end
    end
  end
end
