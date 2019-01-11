describe OddsFeed::Radar::Alive::Message do
  let(:timestamp) { 1_532_353_934_098 }
  let(:message_received_at) { Time.zone.at(timestamp) }
  let(:product) { create(:producer) }

  let(:subscribed_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        "<alive product=\"#{product.id}\" "\
        "timestamp=\"#{timestamp}\" subscribed=\"1\"/>"
    )
  end
  let(:unsubscribed_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        "<alive product=\"#{product.id}\" "\
         "timestamp=\"#{timestamp}\" subscribed=\"0\"/>"
    )
  end

  let(:subscribed_message) { described_class.new(subscribed_payload['alive']) }
  let(:unsubscribed_message) do
    described_class.new(unsubscribed_payload['alive'])
  end

  describe '.initialize' do
    it 'parses product_id' do
      expect(
        subscribed_message.instance_variable_get(:@product_id)
      ).to eq(product.id)
    end

    it 'parses subscribed' do
      expect(
        subscribed_message.instance_variable_get(:@subscribed)
      ).to eq('1')
    end

    it 'parses timestamp' do
      expect(
        subscribed_message.instance_variable_get(:@timestamp)
      ).to eq(timestamp)
    end
  end

  describe '.product' do
    it 'returns product based on alive message' do
      expect(subscribed_message.product).to eq product
    end
  end

  describe '.expired?' do
    before do
      allow(unsubscribed_message).to receive(:product) { product }
    end

    context 'when non-expired' do
      before do
        allow(product)
          .to receive(:last_successful_subscribed_at) {
            message_received_at - 1.minute
          }
      end

      it 'returns false' do
        expect(unsubscribed_message).not_to be_expired
      end
    end

    context 'when expired' do
      before do
        allow(product)
          .to receive(:last_successful_subscribed_at) {
                message_received_at + 1.minute
              }
      end

      it 'returns true' do
        expect(unsubscribed_message).to be_expired
      end
    end
  end

  describe '.subscribed?' do
    it 'returns true for subsribed message' do
      expect(subscribed_message).to be_subscribed
    end

    it 'returns false for unsubscribed message' do
      expect(unsubscribed_message).not_to be_subscribed
    end
  end
end
