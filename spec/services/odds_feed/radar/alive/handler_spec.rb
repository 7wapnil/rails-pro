describe OddsFeed::Radar::Alive::Handler do
  let(:product) { create(:producer) }
  let(:timestamp) { (Time.zone.now.to_f * 1000).to_i }
  let(:message_received_at) { Time.zone.at(timestamp) }
  let(:message) do
    instance_double(OddsFeed::Radar::Alive::Message.name,
                    product: product,
                    timestamp: timestamp,
                    received_at: message_received_at,
                    'subscribed?' => true,
                    'expired?' => false)
  end

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
       "<alive product=\"#{product.id}\" "\
       "timestamp=\"#{timestamp}\" subscribed=\"1\"/>"
    )
  end

  before do
    allow(OddsFeed::Radar::Alive::Message)
      .to receive(:new).with(payload['alive']).and_return(message)
    allow(product).to receive_messages(
      'subscribed!' => true,
      'unsubscribe!' => true
    )
  end

  context '.handle' do
    it 'logs message stats' do
      expect_any_instance_of(JobLogger)
        .to receive(:log_job_message)
        .with(
          :info,
          received_at: message_received_at,
          producer_code: product.code,
          subscription_state: true,
          expired: false
        ).once

      described_class.new(payload).handle
    end

    context 'when alive message describes subscribed product' do
      before do
        described_class.new(payload).handle
      end

      it 'changes product state to subscribed at message received time' do
        expect(product).to have_received(:subscribed!)
          .with(subscribed_at: message_received_at)
          .once
      end
    end

    context 'when alive message describes unsubscribed product' do
      let(:payload) do
        XmlParser.parse(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
          "<alive product=\"#{product.id}\" "\
          "timestamp=\"#{timestamp}\" subscribed=\"0\"/>"
        )
      end

      before do
        allow(message).to receive(:subscribed?).and_return(false)
        described_class.new(payload).handle
      end

      it 'changes product state to unsubscribed' do
        expect(product).to have_received(:unsubscribe!).once
      end
    end

    context 'with expired alive message' do
      let(:message) do
        instance_double('OddsFeed::Radar::Alive::Message',
                        product: product,
                        timestamp: Time.zone.at(timestamp),
                        received_at: Time.zone.at(timestamp),
                        'subscribed?' => false,
                        'expired?' => true)
      end

      let(:response) do
        described_class.new(payload).handle
      end

      before do
        response
      end

      it 'does not change producer state to unsubscribed' do
        expect(product).not_to receive(:unsubscribe!)
      end

      it 'does not change producer state to subscribed' do
        expect(product).not_to receive(:subscribed!)
      end

      it 'returns false from service' do
        expect(response).to be_falsey
      end
    end
  end
end
