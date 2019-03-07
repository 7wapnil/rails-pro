describe OddsFeed::Radar::MarketStatus do
  describe '.stop_status' do
    subject(:stop_status) { described_class.stop_status(code) }

    described_class::MARKET_STATUS_MAP.map do |code, local_status|
      let(:code) { code }

      let(:target_market_status) do
        described_class::MARKET_MODEL_STATUS_MAP[local_status]
      end

      target_status = described_class::MARKET_MODEL_STATUS_MAP[local_status]
      it "converts code #{code} into Market status #{target_status}" do
        expect(stop_status).to eq(target_market_status)
      end
    end

    context 'when missing code passed' do
      let(:code) { nil }

      it 'converts to Market status suspended' do
        expect(stop_status).to eq(Market::SUSPENDED)
      end
    end

    context 'when unsupported code passed' do
      let(:code) { unsupported_status }

      let(:unsupported_status) do
        described_class::MARKET_STATUS_MAP.keys.max + 1
      end

      it('raises ArgumentError with correct message') do
        expect { stop_status }
          .to raise_error ArgumentError, described_class::UNEXPECTED_CODE_MSG
      end
    end
  end
end
